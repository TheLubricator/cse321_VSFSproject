#!/bin/bash
# Run from the repo root: bash tests/run_tests.sh
# Builds both tools, then checks images with tests/tests/verify.py
set -e
cd "$(dirname "$0")/.."
gcc -O2 -std=c17 -Wall -Wextra mkfs_builder.c -o mkfs_builder
gcc -O2 -std=c17 -Wall -Wextra mkfs_adder.c -o mkfs_adder
set +e
head -c 40000 /dev/urandom > mid.txt
mkdir -p sub; echo hi > sub/a.txt; echo hi > a.txt
rm -f z*.img m1*.img p*.img
./mkfs_builder --image z0.img --inode 128 --size-kib 1024 >/dev/null
prev=z0.img; names=()
for i in $(seq 1 20); do
  echo "content $i" > g$i.txt
  timeout 5 ./mkfs_adder --input $prev --output z$i.img --file g$i.txt >/dev/null 2>&1 || { echo "file $i failed rc=$?"; break; }
  prev=z$i.img; names+=(g$i.txt)
done
echo "added: ${#names[@]} files"; python3 tests/verify.py $prev "${names[@]}"
echo "--- 10-block (40000B), 12-block (49152B), 13-block (49153B)"
head -c 49152 /dev/urandom > blk12.txt; head -c 49153 /dev/urandom > blk13.txt
timeout 5 ./mkfs_adder --input z0.img --output m10.img --file mid.txt | tail -1; python3 tests/verify.py m10.img mid.txt
timeout 5 ./mkfs_adder --input z0.img --output m12.img --file blk12.txt | tail -1; python3 tests/verify.py m12.img blk12.txt
timeout 5 ./mkfs_adder --input z0.img --output m13.img --file blk13.txt | tail -1
echo "--- basename stored; 58 ok / 59 rejected; duplicate"
n58=$(printf 'a%.0s' $(seq 1 58)); n59=${n58}a; echo x > "$n58"; echo x > "$n59"
timeout 5 ./mkfs_adder --input z0.img --output p1.img --file sub/a.txt | tail -1; python3 tests/verify.py p1.img a.txt
timeout 5 ./mkfs_adder --input z0.img --output p2.img --file "$n58" | tail -1; python3 tests/verify.py p2.img "$n58"
timeout 5 ./mkfs_adder --input z0.img --output p3.img --file "$n59" | tail -1
timeout 5 ./mkfs_adder --input p1.img --output p4.img --file a.txt | tail -1
echo "--- content roundtrip"
python3 - <<'EOF'
import struct
d=open('m10.img','rb').read()
sb=struct.unpack_from('<IIIQQQQQQQQQQQQII',d,0); its=sb[9]; drs=sb[11]
ino=None
for k in range(64):
    e=d[drs*4096+k*64:drs*4096+k*64+64]
    if e[5:63].split(b'\0')[0]==b'mid.txt': ino=struct.unpack_from('<I',e,0)[0]
raw=d[its*4096+(ino-1)*128:its*4096+ino*128]
size=struct.unpack_from('<Q',raw,12)[0]; direct=struct.unpack_from('<12I',raw,44)
data=b''.join(d[(drs+direct[j])*4096:(drs+direct[j]+1)*4096] for j in range((size+4095)//4096))[:size]
print("roundtrip equal:", data==open('mid.txt','rb').read())
EOF
