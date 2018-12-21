#!/usr/bin/env perl

#######################################
# PPinger
# Script for updating database
# Copyright 2018 duk3L3t0
#######################################

use lib 'include';
use PDraw;
use PMySQL;
use CGI qw(:standard);
use Config::IniFiles;
use Switch;
use strict;

my $config = Config::IniFiles->new( -file => "etc/ppinger.cfg" );
my $queryCGI = CGI->new();
# Try to open database
my $db = PMySQL->new(
    $config->val('SQL', 'db_host'),
    $config->val('SQL', 'db_user'),
    $config->val('SQL', 'db_pass'),
    $config->val('SQL', 'db_name')
);

# Array for fetching MySQL data
my @row = ();












# Close database
$db->DESTROY;

# End of main function
1;
