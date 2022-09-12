# rsync-deleted-files-archive
Bash script for backup based on rsync with deleted file archive functionality

## Quickstart
Download the script and read the comments in order to modify it to your likings. To automate this you can use [systemd timers](https://wiki.archlinux.org/title/Systemd/Timers).

## Note
This script hasn't been tested extensively and it's **not** that good at making sure nothing gets accidentally deleted. So use this at your own risk. If you find any bug, feel free to [open an issue](https://github.com/1nikolas/rsync-deleted-files-archive/issues).

## Why?
Back when I had Windows, I used to have [bvckup2](https://bvckup2.com/) for my backups. This had an option to archive deleted files on a specific directory and then auto-delete them after a certain amount of days. I searched really deep for something like this but the closest thing I got was snapshot rsync apps (like rsnapshot) which create a mess on the backup (I don't want multiple versions of a file, one is fine for me). So I just made this; a simple script which does exactly that, based on rsync.

## How?
This app works by first making a normal copy with rsync and then doing a dry run of `rsync --delete`. Then it parses all the files rsync thinks need to be deleted, moves them into an archive folder and saves them in a "database" to delete in a feature date. For more info on how it works, see the comments inside the script.

## License
```
MIT License
Copyright (c) 2022 Nikolas Spiridakis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
