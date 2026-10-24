import sys, struct, zlib
BS=4096
def check(path, expect_files):
    d=open(path,'rb').read()
    sb=d[:BS]
    f=struct.unpack_from('<IIIQQQQQQQQQQQQII',sb,0)
    magic,ver,bsz,total,icount,ibs,ibb,dbs,dbb,its,itb,drs,drb,root,mtime,flags,crc=f
    b=bytearray(sb); b[112:116]=b'\0\0\0\0'
    assert zlib.crc32(bytes(b[:BS-4]))==crc, "superblock crc"
    assert magic==0x4D565346 and bsz==BS
    ib=d[ibs*BS:(ibs+1)*BS]; db=d[dbs*BS:(dbs+1)*BS]
    ents=[]
    for k in range(64):
        e=d[drs*BS+k*64:drs*BS+k*64+64]
        ino=struct.unpack_from('<I',e,0)[0]
        if ino==0: continue
        x=0
        for c in e[:63]: x^=c
        assert x==e[63], f"dirent xor {k}"
        ents.append((ino,e[4],e[5:63].split(b'\0')[0].decode()))
    names=[n for _,_,n in ents if n not in('.','..')]
    assert names==expect_files, (names,expect_files)
    used_inodes=0
    for ino,t,n in ents:
        if n in('.','..') and ino==1: pass
    seen=set()
    for ino,t,n in ents:
        if ino in seen: continue
        seen.add(ino)
        raw=d[its*BS+(ino-1)*128:its*BS+ino*128]
        crcs=struct.unpack_from('<Q',raw,120)[0]
        t2=bytearray(raw); t2[120:128]=b'\0'*8
        assert zlib.crc32(bytes(t2[:120]))==crcs, f"inode crc {ino}"
        assert ib[(ino-1)//8]>>((ino-1)%8)&1, f"inode bit {ino}"
    return len(ents)
if __name__=='__main__':
    print(check(sys.argv[1], sys.argv[2:]))
