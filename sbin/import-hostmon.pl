#!/usr/bin/env perl

#######################################
# PPinger
# import-hostmon.pl
# Script for importing hosts from
# Advanced Host Monitor.
# https://www.ks-soft.net/hostmon.eng/
# Copyright 2018-2019 duk3L3t0
#######################################

use lib "../include";
use PMySQL;
use Config::IniFiles;
use utf8;
use strict;
use constant FILE => "./hostmon.txt";
binmode(STDOUT,':utf8');

my $config = Config::IniFiles->new( -file => "../etc/ppinger.cfg" );
my $db = PMySQL->new(
    $config->val('SQL', 'db_host'),
    $config->val('SQL', 'db_user'),
    $config->val('SQL', 'db_pass'),
    $config->val('SQL', 'db_name')
) or die("Fatal: Can't connect to database");
my $line;
my @line_arr;
my $var;
my $key;
my @folder_path;
my $folder;
my $folder_id = -1;
my %host = ();

open(InFile, '<:encoding(CP1251)',FILE) || die ("Fatal: Can't open input file");
while($line=<InFile>)
{
    @line_arr = split("=", $line);
    $var = trim($line_arr[0]);
    $key = trim($line_arr[1]);
    if ($var eq ";DestFolder")
    {
        @folder_path = split(/\\/, $key);
        foreach $folder (@folder_path)
        {
            # Check if the folder exists. False: create it. Then get folder's ID.
            if ($db->getFolderIdByName($folder) eq 0)
            {
                print "Creating new folder $folder with id $folder_id...\n";
                $db->createFolder($folder, $folder_id);
            }
            $folder_id = $db->getFolderIdByName($folder);
        }
    }
    elsif ($var eq "Title")
    {
        $host{"comment"} = $key;
    }
    elsif ($var eq "Disabled")
    {
        $host{"status"} = 4;
    }
    elsif ($var eq "Host")
    {
        $host{"host"} = $key;
    }
    elsif ($var eq "Timeout")
    {
        $host{"timeout"} = $key;
    }
    elsif ($var eq "Retries")
    {
        $host{"attempts"} = $key;
        $host{"parentId"} = $folder_id;
        print "Creating new host: ".$host{"host"}."...\n";
        $db->createHost(%host);
        %host = ();
    }
}
close(InFile);

1;

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

