# VSFS: File System Image Builder and Adder

Two command-line tools in C that create and modify a disk image for a small, VSFS-style file system. Built as a CSE321 course project at BRAC University (2025).

- **`mkfs_builder`** creates a new `.img` file system image with initialized metadata and a root directory.
- **`mkfs_adder`** reads an existing image, adds one file to the root directory, and writes the result to a new image.

## On-disk layout

The image consists of the following regions, defined as packed C structs (`superblock_t`, `inode_t`, `dirent64_t`):

| Region | Purpose |
|---|---|
| Superblock | File system geometry and metadata, with a checksum |
| Inode bitmap | Tracks which inodes are free |
| Data bitmap | Tracks which data blocks are free |
| Inode table | Fixed-size inodes; the root directory is inode 0 |
| Data blocks | File contents and directory entries |

Details:

- The root directory is created with `.` and `..` entries.
- CRC32 checksums protect the superblock, inodes, and directory entries.
- Each file may use up to 12 direct blocks.
- File names in directory entries are limited to 58 characters.

## Build

No build system is required; `gcc` is enough (Linux or macOS):

```
gcc -O2 -std=c17 -Wall -Wextra mkfs_builder_skeleton.c -o mkfs_builder
gcc -O2 -std=c17 -Wall -Wextra mkfs_adder_skeleton.c -o mkfs_adder
```

## Usage

### Create an image

```
./mkfs_builder --image out.img --inode 128 --size-kib 1024
```

| Argument | Meaning | Constraint |
|---|---|---|
| `--image` | Output image path | Must end in `.img`; must not already exist |
| `--inode` | Inode count | 128 to 512 |
| `--size-kib` | Image size in KiB | 180 to 4096, divisible by 4 |

### Add a file

```
./mkfs_adder --input out.img --output out1.img --file file_14.txt
```

| Argument | Meaning | Constraint |
|---|---|---|
| `--input` | Existing image | Must exist |
| `--output` | New image to write | Must end in `.img`; must not exist; must differ from `--input` |
| `--file` | File to add | Must exist; must fit in 12 direct blocks; name at most 58 characters |

The adder never modifies the input image in place. To add several files, use each output image as the next input. Adding a file whose name already exists in the root directory is rejected.

Both tools enforce the exact argument format and exit with an error message on any violation.

### Sample files

`file_2.txt`, `file_14.txt`, `file_23.txt`, and `file_27.txt` are small inputs for trying the adder.

## How the adder works

1. Validate the arguments and check that the input exists and the output does not.
2. Load the whole input image into memory.
3. Scan the bitmaps to find a free inode and enough free data blocks.
4. Write the file contents into the allocated blocks and create a root directory entry.
5. Update the root inode and the superblock (modification time and checksum).
6. Write the modified image to the new output path.

## Limitations and future work

- The root directory is limited to the entries that fit in one data block; directory growth is not implemented.
- There is no automated test suite or CI; testing so far has been manual.
- Possible additions: subdirectories, deleting and listing files, and an image consistency checker.
