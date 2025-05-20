# Linux File System Permissions 'Magic Number' Cheat Sheet

| task | source file | source dir | parent dir | ancestor dirs | target dir | target parent dir | target other ancestor dirs |
| ---- |:-----------:|:----------:|:----------:|:-------------:|:----------:|:-----------------:|:--------------------------:|
| read existing file | 4 | - | 1 | 1 | - | - | - |
| append (write) to existing file | 2 | 3 | 1 | 1 | - | - | - |
| delete existing file | - | 3 | 1 | 1 | - | - | - |
| create new file | - | 3 | 1 | 1 | - | - | - |
| rename existing file in same dir | - | 3 | 1 | 1 | - | - | - |
| traverse across or through a directory | - | 1 | 1 | 1 | - | - | - |
| `cd` into directory | - | 1 | 1 | 1 | - | - | - |
| view contents of directory | - | 5 | 1 | 1 | - | - | - |
| delete existing sub-directory | - | - | 2 | 3 | - | - | - |
| create new sub-directory in current directory | - | - | 3 | 1 | - | - | - |
| move existing file to different parent dir | 2 | 3 | 1 | 1 | 3 | 1 | 1 |
| move existing dir to new location (new parent dir) | - | 3 | 3 | 1 | - | 3 | 1 |
| perform action on all files in a directory | 7 | 7 | 1 | 1 | - | - | - |
| load and process a file into a script using SHell source command | 4 | 1 | 1 | 1 | - | - | - |
| `-d` test | - | - | 1 | 1 | - | - | - |
| `-e` test | - | - | 1 | 1 | - | - | - |
| `-f` test | - | - | 1 | 1 | - | - | - |
| `-r` test | 4 | 1 | 1 | 1 | - | - | - |
| `-w` test (file) | 2 | 1 | 1 | 1 | - | - | - |
| `-w` test (dir) | - | 2 | 1 | 1 | - | - | - |
| `-G` test | - | - | 1 | 1 | - | - | - |
| `-O` test | - | - | 1 | 1 | - | - | - |
