#!/usr/bin/perl
#############################################################################################
#
#   Salvage Data Tool
#       Copyright (C) 2013 MATSUMOTO, Ryosuke
#
#   This Code was written by matsumoto_r                 in 2013/07/09 -
#
#   Usage:
#       ./salvage_data.pl
#
#############################################################################################
#
# Change Log
#
# 2013/07/09 matsumoto_r first release
#
#############################################################################################

use strict;
use warnings;
use File::Spec;
use File::Basename;
use File::Path;
use File::Compare;
use DirHandle;
use Cwd;
use lib "./lib";
use Salvage;

our $VERSION        = '0.01';
our $SCRIPT         = basename($0);
our $CDIR           = Cwd::getcwd;

# salvage parameter
# 2013/7/09 12:00 == 1373338800
my $salvage_after   = '1373338800';
my $salvage_dir     = '/tmp';
my $salvage_dev     = '/dev/sdb1';

# salvage tool settings
my $salvage_log     = File::Spec->catfile($CDIR, "rescue.txt");
my $extundelete_dir = File::Spec->catfile($CDIR, "RECOVERED_FILES");
my $saltool_dir     = File::Spec->catfile($CDIR, "tools");
my $salvage_bin     = File::Spec->catfile($saltool_dir, "bin", "extundelete");

# salvage data and suspect_list for client
my $recover_dir     = File::Spec->catfile($CDIR, "SALVAGED_DATA");
my $suspect_list    = File::Spec->catfile($recover_dir, "SUSPECT_LIST.txt");

our $SALVAGE = Salvage->new(

    debug               =>  0,
    info                =>  1,
    warn                =>  1,
    error               =>  1,
    tool_name           =>  "$SCRIPT-$VERSION",
    syslog_type         =>  "$SCRIPT-$VERSION",
    log_file            =>  File::Spec->catfile($CDIR, "$SCRIPT-$VERSION.log"),
    pid_file            =>  File::Spec->catfile($CDIR, "$SCRIPT-$VERSION.pid"),
    lock_file           =>  File::Spec->catfile($CDIR, "$SCRIPT-$VERSION.lock"),
    salvage_bin         =>  $salvage_bin,
    salvage_after       =>  $salvage_after,
    salvage_dir         =>  $salvage_dir,
    salvage_dev         =>  $salvage_dev,
    salvage_log         =>  $salvage_log,
    recover_dir         =>  $recover_dir,
    recovered_files     =>  $extundelete_dir,

);

$SIG{INT}  = sub { $SALVAGE->TASK_SIGINT };
$SIG{TERM} = sub { $SALVAGE->TASK_SIGTERM };

$SALVAGE->info_record(__PACKAGE__." $SCRIPT($VERSION) start");

$SALVAGE->info_record(__PACKAGE__." $SCRIPT locked");
$SALVAGE->set_lock;
$SALVAGE->make_pid_file;

# execute salvage command(extundelete with matsumoto_r patch).
$SALVAGE->info_record(__PACKAGE__." salvage start");
$SALVAGE->exec_salvage;

# create client directory which will be moved into usb.
$SALVAGE->info_record(__PACKAGE__." prepared recovered directory start");
$SALVAGE->prepared_recover_dir;

# pick up duplicate inode log from all salvage log(rescue.txt).
$SALVAGE->info_record(__PACKAGE__." create duplicate log start");
my $duplicate_log_data   = $SALVAGE->create_duplicate_log;

# create duplicate inode list from duplicate log data.
$SALVAGE->info_record(__PACKAGE__." create duplicate inode list start");
my $duplicate_inode_list = $SALVAGE->duplicate_inode_check;

# analyze duplicate data and list which are provided to client and create SUSPECT_LIST.txt.
$SALVAGE->info_record(__PACKAGE__." create suspect list start");
create_suspect_list($duplicate_log_data, $duplicate_inode_list, $suspect_list);

# move the data to client area.
$SALVAGE->info_record(__PACKAGE__." create client data start");
create_salvage_data($recover_dir, $extundelete_dir);

# delete RECOVERD_FILES and rescue.txt
$SALVAGE->info_record(__PACKAGE__." clean up recovered files start");
unlink($salvage_log) if -f $salvage_log;
rmtree($extundelete_dir) if -d $extundelete_dir;

$SALVAGE->info_record(__PACKAGE__." $SCRIPT($VERSION) end");

exit 0;


### sub routine ###

sub create_suspect_list {

    my ($dup_data, $duplicate, $suspect_list) = @_;
    my $sup_data = "";

    foreach my $dinode (keys(%$duplicate)) {
        next if ($$duplicate{$dinode} == 1);

        foreach my $line (@$dup_data) {
            my ($inode, $size, $filename) = (split /\s/, $line)[0, 1, 5];
            if ($dinode eq $inode) {
                $filename =~ s/^RECOVERED_FILES\///;
                # create suspect data from duplicate list
                $sup_data .= "$inode $size $filename\n";
            }
        }
    }
    # write duplicate inode data into SUSPECT_LIST.txt
    $SALVAGE->file_write($suspect_list, "w", $sup_data);
}

sub create_salvage_data {

    my ($recover_dir, $extundelete_dir) = @_;

    $SALVAGE->exec_command("mv $extundelete_dir " . File::Spec->catfile($recover_dir, "."));
}
