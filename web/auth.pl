#!/usr/bin/env perl

#######################################
# PPinger
# auth.pl
# Script for user authentication
# Copyright 2018-2019 duk3L3t0
#######################################

#use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib "../include";
use PDraw;
use PMySQL;
use utf8;
use CGI qw(-utf8);
use CGI::Session qw(-ip-match);
use Config::IniFiles;
use Switch;
use strict;

my $config = Config::IniFiles->new( -file => "../etc/ppinger.cfg" );
my $queryCGI = CGI->new();
my $ui = PDraw->new();
# Try to open database
my $db = PMySQL->new(
    $config->val('SQL', 'db_host'),
    $config->val('SQL', 'db_user'),
    $config->val('SQL', 'db_pass'),
    $config->val('SQL', 'db_name')
);
my $session;
my $cookie;

# Getting input params
my $title = $config->val('Web', 'title');
my $login = $queryCGI->param('login');
my $pass = $queryCGI->param('password');
my $action = $queryCGI->param('action');
# Check what action we need to handle
switch ($action)
{
    case "logout"
    {
        # Remove session id and draw login page
        if ( $queryCGI->cookie('SESSION_ID') )
        {
            $session = new CGI::Session("driver:File", $queryCGI->cookie('SESSION_ID'), {Directory=>"/tmp"});
            if ($session) { $session->delete(); }
            $cookie = $queryCGI->cookie(
                        -name => "SESSION_ID",
                        -value => $queryCGI->cookie('SESSION_ID'),
                        -expires => "-1d" );
            $ui->showLoginPage($title, undef, $cookie);
        }
        else
        {
            $ui->showLoginPage($title);
        }
    }
    else
    {
        # Check for login and pass
        if (($login)&&($pass))
        {
            # Compare with config and send to index.pl or auth.pl?action=fail
            #$pass = md5($pass);
            if ( ($config->val('Web', 'username') eq $login)&&($config->val('Web', 'password') eq $pass) )
            {
                # Generate and write new session id
                $session = new CGI::Session("driver:File", undef, {Directory=>"/tmp"});
                $session->expire('+1h');
                $cookie = $queryCGI->cookie( SESSION_ID => $session->id() );
                print $queryCGI->redirect( -uri => "./index.pl", -cookie => $cookie );
            }
            else
            {
                # Login or pass are wrong
                $ui->showLoginPage($title, "Login failed");
            }
        }
        else
        {
            # Compare server and user side session IDs
            if ( $queryCGI->cookie('SESSION_ID') )
            {
                $session = new CGI::Session("driver:File", $queryCGI->cookie('SESSION_ID'), {Directory=>"/tmp"});
                if ( $session->id() eq $queryCGI->cookie('SESSION_ID') )
                {
                    print $queryCGI->redirect("index.pl");
                }
                else
                {
                    $session->delete();
                    $ui->showLoginPage($title);
                }
            }
            else
            {
                $ui->showLoginPage($title);
            }
        }
    }
}

# Close database
$db->DESTROY();

# End of main function
1;
