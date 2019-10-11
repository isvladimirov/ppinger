#!/usr/bin/env perl

#######################################
# PPinger
# ppoller.pl
# Script for polling hosts
# Copyright 2018-2019 duk3L3t0
#######################################

use lib "/opt/ppinger/include";
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
my $i;
my $triggerRised = 0;
my $message;
my $hostsDown;

print "Loading settings...\n" if DEBUG;
my $config = Config::IniFiles->new( -file => "/opt/ppinger/etc/ppinger.cfg" );
print "Try to open database...\n" if DEBUG;
my $db = PMySQL->new(
    $config->val('SQL', 'db_host'),
    $config->val('SQL', 'db_user'),
    $config->val('SQL', 'db_pass'),
    $config->val('SQL', 'db_name')
);

my $tgToken = $config->val('Poller', 'tg_token');

print "Checking hosts...\n" if DEBUG;
my $poller = PPoller->new();

while ($continue)
{
    for ($i=0; $i<scalar @order; $i++)
    {
        $status = $order[$i];
        print "Getting host list with status $status..." if DEBUG;
        $sth = $db->getHostList(0, $status);
        print " OK\n" if DEBUG;
        while (@row = $sth->fetchrow_array())
        {
            print "Getting host information..." if DEBUG;
            $host{"id"} = $row[0];
            $host{"host"} = $row[1];
            $host{"method"} = $row[5];
            $host{"port"} = $row[6];
            $host{"attempts"} = $row[7];
            $host{"timeout"} = $row[8];
            $host{"command"} = $row[13];
            print " OK\n" if DEBUG;
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
            print "Updating host..." if DEBUG;
            $db->updateHostStatus($host{"id"}, $status, $reply, $config->val('Poller', 'max_log_count'));
            print " OK\n" if DEBUG;
        }
        $sth->finish();
    }
# Trigger
    $hostsDown = $db->countHostStatus(STATUS_DOWN);
    if ( $hostsDown>=$config->val('Poller', 'trigger_count') )
    {
        if ( !($triggerRised) )
        {
            print "Trigger rised. Sending message...\n" if DEBUG;
            $message = "DTL_PPinger. Внимание! Количество упавших узлов превысило пороговое значение (".$config->val('Poller', 'trigger_count').") и составляет $hostsDown.";
            `wget -O /dev/null \"http://crierbot.appspot.com/$tgToken/send?message=$message\" > /dev/null`;
            $triggerRised = 1;
        }
    }
    else
    {
        if ( $triggerRised )
        {
            print "Trigger down. Sending message...\n" if DEBUG;
            $message = "DTL_PPinger. Количество упавших узлов пришло в норму (".$config->val('Poller', 'trigger_count').") и составляет $hostsDown.";
            `wget -O /dev/null \"http://crierbot.appspot.com/$tgToken/send?message=$message\" > /dev/null`;
            $triggerRised = 0;
        }
    }
# Delay before next check iteration
    sleep ($config->val('Poller', 'interval'));
}

print "Closing database...\n" if DEBUG;
$db->DESTROY();

print "Exit.\n" if DEBUG;
# End of main function
1;
