#!/usr/bin/env perl

#######################################
# PPinger
# index.pl
# Point of entrance
# Copyright 2018-2019 duk3L3t0
#######################################

use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib "../include";
require "PCore.pl";
use PDraw;
use PMySQL;
use utf8;
use CGI qw(-utf8);
use Config::IniFiles;
use Switch;
use strict;
use constant
{
    APP_VERSION => "0.9 (developing)",
    STATUS_ALL => 0,
    STATUS_DOWN => 1,
    STATUS_ALIVE => 2,
    STATUS_UNKNOWN => 3,
    STATUS_DISABLED => 4,
};

my %statusName = ( 1 => "down",
                   2 => "alive",
                   3 => "unknown",
                   4 => "disabled",
                 );
my $config = Config::IniFiles->new( -file => "../etc/ppinger.cfg" );
my $queryCGI = CGI->new();
# Try to open database
my $db = PMySQL->new(
    $config->val('SQL', 'db_host'),
    $config->val('SQL', 'db_user'),
    $config->val('SQL', 'db_pass'),
    $config->val('SQL', 'db_name')
) or die("Error! Can't connect to database!");
# Open output
my $ui = PDraw->new();
my $title = $config->val('Web', 'title');
my $refresh = 0;
my $action = $queryCGI->param('action');
my $folderId = $queryCGI->param('folder_id');
my $hostId = $queryCGI->param('host_id');
my $queryStatus = $queryCGI->param('status');
my $editMode = $queryCGI->cookie('EDIT_MODE');
my $hash;
my $cookie;
my $sessionID = $queryCGI->cookie('SESSION_ID');
my %hostStatus = ( "total"    => $db->countHostStatus(),
                   "down"     => $db->countHostStatus(STATUS_DOWN),
                   "alive"    => $db->countHostStatus(STATUS_ALIVE),
                   "unknown"  => $db->countHostStatus(STATUS_UNKNOWN),
                   "disabled" => $db->countHostStatus(STATUS_DISABLED),
                 );

# TODO
# Here will be a block for comparing cookie's and DB's session IDs
# If they are not equal go to auth.pl?action=login

# Validate params
$folderId =~ /^\d+?$/ or $folderId = 0;
$hostId =~ /^\d+?$/ or $hostId = 0;
( ($queryStatus>0) && ($queryStatus<4) ) or $queryStatus = 0;

switch ($action)
{
    case "edit"
    {
        # Toggle edit mode
        if ($editMode)
        {
            # Edit mode is on. Turn it off.
            $cookie = new CGI::Cookie(-name=>'EDIT_MODE',-value=>'0');
            $editMode = 0;
            $action = "view";
            $refresh = $config->val('Web', 'refresh');
            $title .= " :: View mode";
        }
        else
        {
            # Edit mode is off. Turn it on.
            $cookie = new CGI::Cookie(-name=>'EDIT_MODE',-value=>'1');
            $editMode = 1;
            $title = $title . " :: Configuration mode";
        }
    }
    case "edit_folder" { $title = $title . " :: Edit folder"; }
    case "edit_host"   { $title = $title . " :: Edit host"; }
    case "show_host"   { $title = $title . " :: Host details"; }
    case "show_logs"   { $title = $title . " :: Quick logs"; }
    else
    {
        # Draw main form
        if ($editMode)
        {
            $title = $title . " :: Configuration mode";
        }
        else
        {
            $refresh = $config->val('Web', 'refresh');
            $title .= " :: View mode";
        }
    }
}

switch ($queryStatus)
{
    case STATUS_ALIVE   { $title .= " :: Alive"; }
    case STATUS_DOWN    { $title .= " :: Down"; }
    case STATUS_UNKNOWN { $title .= " :: Unknown"; }
}

# Draw header
$ui->addHeader($title, $refresh, $cookie, %hostStatus);
# Draw folders
$ui->openFolders($editMode);
drawFolderField($db, $ui, -1, 0, $folderId, $editMode);
$ui->closeFolders();

switch ($action)
{
    case "edit_folder"
    {
        # Draw edit form for a folder
        $hash = $db->getFolderList(0);
        $ui->editFolder($folderId,
                        $db->getFolderNameById($folderId),
                        $db->getFolderParentById($folderId),
                        $hash);
        $hash->finish();
    }
    case "edit_host"
    {
        # Draw edit form for a host
        $ui->editHost($db->getFolderList(0), $db->getHostById($hostId));
    }
    case "show_host"
    {
        # Draw host details
        $ui->showHost($db->getHostLogs($hostId), $db->getHostById($hostId));
    }
    case  "show_logs"
    {
        # Draw quick logs
        $ui->openLogs();
        my @row;
        $hash = $db->getHostLogs();
        while ( @row = $hash->fetchrow_array() )
        {
            $ui->addLog("Host ".$db->getHostNameById($row[3])." become ".$statusName{$row[1]}." at $row[2]", $row[1]);
        }
        $ui->closeLogs();
    }
    
    else
    {
        # Draw hosts
        $ui->openHosts($editMode);
        drawHostField($db, $ui, $folderId, $config->val('Web', 'sub_folders'), $editMode, $queryStatus);
        $ui->closeHosts();
    }
}

# Draw footer
my $message = "PPinger v".(APP_VERSION);
$message .= " | Total hosts: ".$hostStatus{"total"};
$message .= " | Alive: ".$hostStatus{"alive"};
$message .= " | Down: ".$hostStatus{"down"};
$message .= " | Unknown: ".$hostStatus{"unknown"};
$ui->addFooter($message);

# Close database
$db->DESTROY;
# End of main function
1;
