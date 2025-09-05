# cse321_VSFSproject_limitedAccess
limited access view  only,  will  receive updated code late


sample inps after compilation
./mkfsbuilder.exe --image out.img --inode 128 --size-kib 1024


./mkfsadder.exe --input out.img --output out1.img --file file_14.txt

for builder-> file extensiion  must  be img. Also will not  overwrite if an  img  file same as input exists. CLI structure is strictly enforced ie even different spelling wont work.  Builds img  according to specifications

for adder->Like  builder, CLI structure is strictly  enforced. Wont work if->file doesnt exist, input  image doesnt exist, input image same as output image, file size and/or name too large.
          Reads img, loads  it to memory, uses  necessary steps  to add file to root, then "writes everything to new image under output". 
          This implies, the image that  is updated is the output  image, and input image is  only accessed.  So,  to check for duplications, CLI command must take the  image written by adder  in previous run as input, and  oouput a different image file and  then check for duplication
   time: 5/9/2025 7:44 PM-> incorrect  error handling for invalid  file extension fixed
