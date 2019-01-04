#!/usr/bin/env perl

#######################################
# PPinger
# index.pl
# Point of entrance
# Copyright 2018 duk3L3t0
#######################################

use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib "include";
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
    APP_VERSION => 0.5,
    STATUS_ALL => 0,
    STATUS_DOWN => 1,
    STATUS_ALIVE => 2,
    STATUS_UNKNOWN => 3,
    STATUS_DISABLED => 4,
};

my $config = Config::IniFiles->new( -file => "etc/ppinger.cfg" );
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
my $editMode = $queryCGI->cookie('EDIT_MODE');
my $hash;
my $cookie;
my $message="Nothing interesting";

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
            $message = "Edit mode is turned off";
        }
        else
        {
            # Edit mode is off. Turn it on.
            $cookie = new CGI::Cookie(-name=>'EDIT_MODE',-value=>'1');
            $editMode = 1;
            $title = $title . " :: Configuration mode";
            $message = "Edit mode is turned on";
        }
    }
    case "edit_folder"
    {
        $editMode = 1;
        $title = $title . " :: Edit folder";
    }
    case "edit_host"
    {
        $editMode = 1;
        $title = $title . " :: Edit host";
    }
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

# Validate params
$folderId =~ /^\d+?$/ or $folderId = 0;
$hostId =~ /^\d+?$/ or $hostId = 0;

# Draw header
$ui->addHeader($title, $refresh, $cookie);

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
        # Draw edit form for a folder
        $hash = $db->getFolderList(0);
        $ui->editHost($hostId,
                        $db->getHostNameById($hostId),
                        $db->getHostParentById($hostId),
                        $hash,
                        $db->getHostCommentById($hostId));
        $hash->finish();
    }
    else
    {
        # Draw hosts
        $ui->openHosts($editMode);
        drawHostField($db, $ui, $folderId, $config->val('Web', 'sub_folders'), $editMode);
        $ui->closeHosts();
    }
}

# Draw footer
$ui->addFooter("PPinger v".(APP_VERSION)." | Разрабатываемая версия | $message");

# Close database
$db->DESTROY;

# End of main function
1;
