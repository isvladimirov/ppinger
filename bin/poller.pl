#!/usr/bin/env perl

#######################################
# PPinger
# poller.pl
# Script for polling hosts
# Copyright 2018-2019 duk3L3t0
#######################################

use lib "../include";
use PMySQL;
use strict;
use constant
{
    STATUS_ALL => 0,
    STATUS_DOWN => 1,
    STATUS_ALIVE => 2,
    STATUS_UNKNOWN => 3,
    STATUS_DISABLED => 4,
};

my $config = Config::IniFiles->new( -file => "../etc/ppinger.cfg" );
# Try to open database
my $db = PMySQL->new(
    $config->val('SQL', 'db_host'),
    $config->val('SQL', 'db_user'),
    $config->val('SQL', 'db_pass'),
    $config->val('SQL', 'db_name')
);

#
# TODO: Here will be main code of a poller
#

# Close database
$db->DESTROY();

# End of main function
1;
