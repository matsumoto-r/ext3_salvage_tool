# ext3 file system salvage tool
Need Perl Modules
class accessor

implemented duplicate check to extundelete.

## Compile salvage tool

```
cd tools
yum -y install e2fsprogs-devel
aclocal
automake
autoconf
./configure --prefix=`pwd`
make
make install
```

## SALVAGE
- set salvage params

```
vi salvage_data.pl
```
```perl
# salvage parameter
# 2013/7/09 12:00 == 1373338800
# $salvage_after: only process entries deleted on or after 'dtime'.
# $salvage_dir:   target directory for undelete
# $salvage_dev:   target device-file
my $salvage_after   = '1373338800';
my $salvage_dir     = '/tmp';
my $salvage_dev     = '/dev/sdb1';
```

- run

```
./salvage_data.pl
```

- undelete data into ``SALVAGED_DATA/RECOVERED_FILES/$(full-path-files)``
- duplicated inode list into ``SALVAGED_DATA/SUSPECT_LIST.txt``
