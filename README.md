# cse321_VSFSproject_limitedAccess

## Overview

This repository contains two C programs that work with a small custom filesystem image format (VSFS-style coursework skeleton):

- `mkfs_builder_skeleton.c`: creates a new `.img` filesystem image with initialized metadata and a root directory.
- `mkfs_adder_skeleton.c`: reads an existing image, adds one file entry into the root directory, and writes a new output image.

The repository also includes sample text files (`file_2.txt`, `file_14.txt`, `file_23.txt`, `file_27.txt`) that can be used as input to the adder.

## Project Structure and Components

- `/home/runner/work/cse321_VSFSproject_limitedAccess/cse321_VSFSproject_limitedAccess/mkfs_builder_skeleton.c`
  - Defines packed on-disk structs: `superblock_t`, `inode_t`, `dirent64_t`.
  - Initializes CRC/checksum helpers (`crc32`, `inode_crc_finalize`, `dirent_checksum_finalize`).
  - Validates CLI format and basic numeric ranges.
  - Creates an in-memory image buffer, initializes:
    - superblock
    - inode bitmap
    - data bitmap
    - inode table (root inode)
    - root directory entries (`.` and `..`)
  - Writes the image to disk and runs read-back diagnostics.

- `/home/runner/work/cse321_VSFSproject_limitedAccess/cse321_VSFSproject_limitedAccess/mkfs_adder_skeleton.c`
  - Uses the same on-disk struct layouts and checksum helpers.
  - Validates CLI arguments and existence/separation of input/output files.
  - Loads the input image into memory.
  - Locates free inode/data blocks via bitmap scanning.
  - Writes file content into allocated data blocks and creates a root dirent.
  - Updates root inode metadata and superblock mtime/checksum.
  - Writes the modified image to a *new* output image file.

## Core Workflow / Data Flow

1. Build both binaries.
2. Create a fresh filesystem image with `mkfs_builder_skeleton.c`.
3. Add a file with `mkfs_adder_skeleton.c`, producing a new image.
4. For additional additions, use the previous output image as the next input image.

The adder does **not** modify the input image in place; it reads input and writes a separate output file.

## Build and Run

No build system (Makefile/CMake) is present. Use `gcc` directly.

### Build

```bash
gcc -O2 -std=c17 -Wall -Wextra mkfs_builder_skeleton.c -o mkfs_builder
gcc -O2 -std=c17 -Wall -Wextra mkfs_adder_skeleton.c -o mkfs_adder
```

### Create an image

```bash
./mkfs_builder --image out.img --inode 128 --size-kib 1024
```

Expected CLI format is strict:

```text
--image <output image> --inode <inode size/count argument> --size-kib <size in KiB>
```

Constraints enforced by current code:

- output name must end in `.img`
- output image must not already exist
- `--inode` value must be in `[128, 512]`
- `--size-kib` must be in `[180, 4096]` and divisible by 4

### Add a file

```bash
./mkfs_adder --input out.img --output out1.img --file file_14.txt
```

Expected CLI format is strict:

```text
--input <input image> --output <output image> --file <file path>
```

Constraints enforced by current code:

- output name must end in `.img`
- input image must exist
- file to add must exist
- input and output image paths must differ
- output image must not already exist
- file must fit within 12 direct blocks
- filename stored in dirent is limited to 58 chars
- duplicate root-level names are rejected

> Important: duplicate checking and filename-length checks use the raw `--file` argument string. Passing a long absolute path may fail filename-length validation even if the basename is short.

## Dependencies and Environment

Based on includes and syscalls used by the source:

- C17 compiler (tested via `gcc`)
- POSIX-style runtime APIs (`unistd.h`, `fcntl.h`, `open`, `write`, `access`, etc.)
- Standard C library headers (`stdio.h`, `stdlib.h`, `string.h`, `stdint.h`, `time.h`, ...)

This is expected to run in Unix-like environments (Linux/macOS). No Windows-specific build/run path is provided in code.

## Readiness / Current Status (Evidence-Based)

### Implemented and working (manually verified)

- Both programs compile successfully with the commands above.
- Builder creates an image and prints diagnostic verification output.
- Adder can add a sample text file and emit a new output image.
- Adder rejects duplicate root filenames when rerun against a previously updated image.

### Known issues / incompleteness observed in current code

- Compilation emits warnings in both C files (unused variables, unchecked `write` return values, and a `printf` format mismatch in adder CLI error path).
- No automated test suite, CI config, or build automation is present in the repository.
- Root directory handling appears limited to entries in a single root data block (no directory growth logic implemented).
- Error handling is partial in places (some resources and return values are not fully checked).
- Filenames are taken directly from `--file` argument instead of normalized basename.

Given the above, the project appears to be a **functional coursework prototype/skeleton**, not production-ready filesystem tooling.

## Testing and Development Notes

- There are no repository tests to run.
- Validation currently depends on manual CLI execution and printed diagnostics.
- If this project is extended, adding a build script and automated tests for CLI validation, image consistency, and edge cases would improve confidence.
