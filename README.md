# ext3 file system salvage tool
Need Perl Modules
class accessor

implemented duplicate check to extundelete.

## Compile salvage tool
``
cd tools
yum -y install e2fsprogs-devel
./configure --prefix=`pwd`
make
make install
``

## SALVAGE
- set salvage params
``
vi salvage_data.pl
``
``perl
# salvage parameter
# 2013/7/09 12:00 == 1373338800
my $salvage_after   = '1373338800';
my $salvage_dir     = '/';
my $salvage_dev     = '/dev/sdb1';
``

- run
``
./salvage_data.pl
``

