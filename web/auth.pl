#!/usr/bin/env perl

#######################################
# PPinger
# auth.pl
# Script for user authentication
# Copyright 2018-2019 duk3L3t0
#######################################

use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib "../include";
use PDraw;
use PMySQL;
use CGI qw(:standard);
use Config::IniFiles;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Switch;
use strict;

my $config = Config::IniFiles->new( -file => "../etc/ppinger.cfg" );
my $queryCGI = CGI->new();
# Try to open database
my $db = PMySQL->new(
    $config->val('SQL', 'db_host'),
    $config->val('SQL', 'db_user'),
    $config->val('SQL', 'db_pass'),
    $config->val('SQL', 'db_name')
);
# Clean up old session IDs
# Not implemented yet

# Getting input params
my $sessionID = $queryCGI->cookie('SESSION_ID');
my $login = $queryCGI->param('login');
my $pass = $queryCGI->param('password');
my $action = $queryCGI->param('action');
# Check what action we need to handle
switch ($action)
{
    case "login"
    {
        # Just draw login page here
    }
    case "fail"
    {
        # Same as "login", but print fail message
    }
    case "logout"
    {
        # Same as "login", but remove session id from database and user side
    }
    else
    {
        # Check for login and pass
        if (($login)&&($pass))
        {
            # Compare with config and send to index.pl or auth.pl?action=fail
            $pass = md5($pass);
        }
        else
        {
            # Check for session id, compare it with database,
            # send to index.pl or auth.pl?action=login
        }
    }
}

# Close database
$db->DESTROY();

# End of main function
1;
