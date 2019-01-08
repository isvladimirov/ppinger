#!/usr/bin/env perl

#######################################
# PPinger
# poller.pl
# Script for polling hosts
# Copyright 2018-2019 duk3L3t0
#######################################

use lib "../include";
use PMySQL;
use Config::IniFiles;
use strict;
use constant
{
    DEBUG => 1, # '0' - Debug is OFF, '1' - Debug is ON
    STATUS_ALL => 0,
    STATUS_DOWN => 1,
    STATUS_ALIVE => 2,
    STATUS_UNKNOWN => 3,
    STATUS_DISABLED => 4,
};

!DEBUG or print "Loading settings...\n";
my $config = Config::IniFiles->new( -file => "../etc/ppinger.cfg" );

!DEBUG or print "Try to open database...\n";
my $db = PMySQL->new(
    $config->val('SQL', 'db_host'),
    $config->val('SQL', 'db_user'),
    $config->val('SQL', 'db_pass'),
    $config->val('SQL', 'db_name')
);

!DEBUG or print "Polling downed hosts...\n";
!DEBUG or print "Polling unknown hosts...\n";
!DEBUG or print "Polling alive hosts...\n";
#
# TODO: Here will be main code of a poller
#

!DEBUG or print "Closing database...\n";
$db->DESTROY();

!DEBUG or print "Exit.\n";
# End of main function
1;
