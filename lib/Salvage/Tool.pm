#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package Salvage::Tool;

use strict;
our $VERSION = '0.01';

sub exec_salvage {

    my $self = shift;

    my $salvage_cmd = $self->salvage_bin . " --after " . $self->salvage_after . " --restore-directory=" . $self->salvage_dir . " --duplicate " . $self->salvage_dev . " > " . $self->salvage_log . " 2>&1";

    $self->error_record(__PACKAGE__." salvage binary ". $self->salvage_bin ." not found") if ! -f $self->salvage_bin;
    $self->error_record(__PACKAGE__." salvage log " . $self->salvage_log . " found") if -f $self->salvage_log;
    $self->exec_command($salvage_cmd, 0);

}

sub prepared_recover_dir {

    my $self = shift;

    $self->debug_record(__PACKAGE__." prepared recovery directory: " . $self->recover_dir);
    mkdir($self->recover_dir, 0755) if ! -d $self->recover_dir;
}

sub create_duplicate_log {
    
    my $self = shift;

    $self->debug_record(__PACKAGE__." create duplicate data from log: " . $self->salvage_log);
    my @dup_data = sort (grep { $_ =~ /Duplicated inode Check:/ } $self->file_read($self->salvage_log));
    $self->dup_data(\@dup_data);

    return $self->dup_data;
}

sub duplicate_inode_check {

    my $self = shift;

    my %duplicate = ();
    $self->debug_record(__PACKAGE__." duplicate inode counting");
    my $dup_data_ref = $self->dup_data;
    foreach my $line (@$dup_data_ref) {
        my $inode = (split /\s/, $line)[0];
        $duplicate{$inode}++;
    }

    return \%duplicate;
}

1;
