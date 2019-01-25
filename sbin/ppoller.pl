#!/usr/bin/env perl

#######################################
# PPinger
# ppoller.pl
# Script for polling hosts
# Copyright 2018-2019 duk3L3t0
#######################################

use lib "../include";
use PMySQL;
use PPoller;
use Config::IniFiles;
use Data::Validate::IP qw(is_ip);
use Data::Validate::Domain qw(is_domain);
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
my $continue = 1;
$SIG{TERM} = sub { $continue = 0 };
# Order of host check
my @order = (STATUS_DOWN, STATUS_UNKNOWN, STATUS_ALIVE);
my $status;
my @row;
my %host;
my $reply;
my $sth;

print "Loading settings...\n" if DEBUG;
my $config = Config::IniFiles->new( -file => "../etc/ppinger.cfg" );

print "Try to open database...\n" if DEBUG;
my $db = PMySQL->new(
    $config->val('SQL', 'db_host'),
    $config->val('SQL', 'db_user'),
    $config->val('SQL', 'db_pass'),
    $config->val('SQL', 'db_name')
);

print "Checking hosts...\n" if DEBUG;
my $poller = PPoller->new();
while ($continue)
{
    foreach $status (@order)
    {
        $sth = $db->getHostList();
        while (@row = $sth->fetchrow_array())
        {
            $host{"host"} = $row[1];
            $host{"method"} = $row[5];
            $host{"port"} = $row[6];
            $host{"attempts"} = $row[7];
            $host{"timeout"} = $row[8];
            $host{"command"} = $row[13];
            print "Checking ".$host{"host"}." with ".$host{"method"}."... " if DEBUG;
            if ( (is_ip($host{"host"})) || (is_domain($host{"host"})) )
            {
                ($status, $reply) = $poller->checkHost(%host);
                if ( $status )
                {
                    $status = STATUS_ALIVE;
                    print "[alive]\n" if DEBUG;
                }
                else
                {
                    $status = STATUS_DOWN;
                    print "[down]\n" if DEBUG;
                }
            }
            else
            {
                $status = STATUS_DISABLED;
                print "[wrong address] This host will be disabled.\n" if DEBUG;
            }
            $db->updateHostStatus($row[0], $status, $reply, $config->val('Poller', 'max_log_count'));
        }
        $sth->finish();
    }
    sleep ($config->val('Poller', 'interval'));
}
print "Closing database...\n" if DEBUG;
$db->DESTROY();

print "Exit.\n" if DEBUG;
# End of main function
1;
