#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package Salvage;

use strict;
use base "Super";
use base qw(
    Salvage::File
    Salvage::Command
    Salvage::Log
    Salvage::Record
    Salvage::Message
    Salvage::Pid
    Salvage::Lock
    Salvage::Tool
);

__PACKAGE__->mk_accessors(qw(
    debug           
    info            
    warn            
    error           
    log_file        
    tool_name       
    syslog_type     
    syslog_priority 
    pid_file        
    lock_file       
    user_name       
    salvage_bin
    salvage_after
    salvage_dir
    salvage_dev
    salvage_log
    recover_dir
    recovered_files
    dup_data
    lock_fd         
    already_running 
    exit_code
));

our $VERSION = '0.01';

$ENV{'IFS'}     = '' if $ENV{'IFS'};
$ENV{'PATH'}    = '/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin';
$ENV{'LC_TIME'} = 'C';
umask(022);

sub new {

    my ($class, %args) = @_;

    my $self = bless {

        debug               =>  (exists $args{debug})            ? $args{debug}             :   0,
        info                =>  (exists $args{info})             ? $args{info}              :   0,
        warn                =>  (exists $args{warn})             ? $args{warn}              :   0,
        error               =>  (exists $args{error})            ? $args{error}             :   0,
        log_file            =>  (exists $args{log_file})         ? $args{log_file}          :   "/tmp/operation-tool-$ENV{USR}.log",
        tool_name           =>  (exists $args{tool_name})        ? $args{tool_name}         :   'operation-tool',
        syslog_type         =>  (exists $args{syslog_type})      ? $args{syslog_type}       :   'operation-system',
        syslog_priority     =>  (exists $args{syslog_priority})  ? $args{syslog_priority}   :   'local3.notice',
        pid_file            =>  (exists $args{pid_file})         ? $args{pid_file}          :   '/tmp/operation-tool.pid',
        lock_file           =>  (exists $args{lock_file})        ? $args{lock_file}         :   '/tmp/operation-tool.lock',
        user_name           =>  (exists $args{user_name})        ? $args{user_name}         :   $ENV{USER},
        salvage_bin         =>  (exists $args{salvage_bin})      ? $args{salvage_bin}       :   undef,
        salvage_after       =>  (exists $args{salvage_after})    ? $args{salvage_after}     :   undef,
        salvage_dir         =>  (exists $args{salvage_dir})      ? $args{salvage_dir}       :   undef,
        salvage_dev         =>  (exists $args{salvage_dev})      ? $args{salvage_dev}       :   undef,
        salvage_log         =>  (exists $args{salvage_log})      ? $args{salvage_log}       :   undef,
        recover_dir         =>  (exists $args{recover_dir})      ? $args{recover_dir}       :   undef,
        recovered_files     =>  (exists $args{recovered_files})  ? $args{recovered_files}   :   undef,
        dup_data            =>  undef,
        lock_fd             =>  undef,
        already_running     =>  0,
        exit_code           =>  0,    

    }, $class;

    $self->debug_record(__PACKAGE__." call new");
    $self->debug_record(__PACKAGE__." [new] executed.", $self->debug);
    $self->initialization;

    return $self;
}


sub initialization {

    my $self = shift;

    $self->debug_record(__PACKAGE__." call initialization");
    $self->error_record(__PACKAGE__." salvage_bin arg not found.") if ! defined($self->salvage_bin);
    $self->error_record(__PACKAGE__." salvage_dir arg not found.") if ! defined($self->salvage_dir);
    $self->error_record(__PACKAGE__." salvage_dev arg not found.") if ! defined($self->salvage_dev);
    $self->error_record(__PACKAGE__." salvage_log arg not found.") if ! defined($self->salvage_log);
    $self->error_record(__PACKAGE__." recover_dir arg not found.") if ! defined($self->recover_dir);
    $self->error_record(__PACKAGE__." salvage_after arg not found.") if ! defined($self->salvage_after);
    $self->error_record(__PACKAGE__." recovered_files arg not found.") if ! defined($self->recovered_files);

    $self->debug_record(__PACKAGE__." salvage_bin: " . $self->salvage_bin);
    $self->debug_record(__PACKAGE__." salvage_dir: " . $self->salvage_dir);
    $self->debug_record(__PACKAGE__." salvage_dev: " . $self->salvage_dev);
    $self->debug_record(__PACKAGE__." salvage_log: " . $self->salvage_log);
    $self->debug_record(__PACKAGE__." recover_dir: " . $self->recover_dir);
    $self->debug_record(__PACKAGE__." salvage_after: " . $self->salvage_after);
    $self->debug_record(__PACKAGE__." recovered_files: " . $self->recovered_files);
}

sub DESTROY {

    my $self = shift;

    my $unlink_log_size = 1000000;

    $self->debug_record(__PACKAGE__." call destructor");
    $self->debug_record(__PACKAGE__." [DESTROY] execute unlink_pid_file and set_unlock", $self->debug);

    if ($self->already_running == 1) {
        $self->unlink_pid_file;
        $self->set_unlock;
        my $log_size = -s $self->log_file;
        unlink $self->log_file if $log_size > $unlink_log_size;
    }

    exit $self->exit_code;
}
