#!/usr/bin/env perl

#######################################
# PPinger
# index.pl
# Point of entrance
# Copyright 2018 duk3L3t0
#######################################

use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib 'include';
use PDraw;
use PMySQL;
use utf8;
use CGI qw(-utf8);
use Config::IniFiles;
use Switch;
use strict;

use constant
{
    APP_VERSION => 0.4,
    STATUS_ALL => 0,
    STATUS_DOWN => 1,
    STATUS_ALIVE => 2,
    STATUS_UNKNOWN => 3,
    STATUS_DISABLED => 4,
};

# Recursive function for drawing folder tree
sub drawFolderField;
# Recursive function for drawing hosts
sub drawHostField;

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

# Validate $folderId
$folderId =~ /^\d+?$/ or $folderId = 0;

# Draw header
if ($cookie)
{
    print $queryCGI->header(-type=>"text/html;charset=UTF-8",-cookie=>$cookie);
}
else
{
    print $queryCGI->header(-type=>"text/html;charset=UTF-8");
}
$ui->addHeader($title, $refresh);

# Draw folders
$ui->openFolders($editMode);
drawFolderField($db, $ui, -1, 0, $folderId);
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
    else
    {
        # Draw hosts
        $ui->openHosts($editMode);
        drawHostField($folderId, $config->val('Web', 'sub_folders'));
        $ui->closeHosts();
    }
}

# Draw footer
$ui->addFooter("PPinger v".(APP_VERSION)." | Разрабатываемая версия | $message");

# Close database
$db->DESTROY;

# End of main function
1;

sub drawFolderField
{
    my ($sourceDB, $destinationUI, $parent, $level, $folderId) = @_;
    my @row = ();
    my $sth = $sourceDB->getFolderList($parent);
    while (@row = $sth->fetchrow_array)
    {
        $destinationUI->addFolder($editMode, $row[1], $row[0], $level, 0, $folderId);
        drawFolderField($sourceDB, $destinationUI, $row[0], $level+1, $folderId);
    }
    $sth->finish();
    return 1;
}

sub drawHostField
{
    my ($parent, $isRecursive) = @_;
    my @row = ();
    if (($parent==0)&&($isRecursive))
    {
        $parent=-1;
    }
    my $sth = $db->getHostList($parent);
    
    # Draw host is the current folder
    while (@row = $sth->fetchrow_array)
    {
        switch ($row[3])
        {
            case (STATUS_DOWN)     { $row[3] = "down"; }
            case (STATUS_ALIVE)    { $row[3] = "alive"; }
            case (STATUS_UNKNOWN)  { $row[3] = "unknown"; }
            case (STATUS_DISABLED) { $row[3] = "disabled"; }
        }
        $ui->addHost($editMode, # Turn on edit mode
        $row[1],   # Hostname
        $row[0],   # Host ID
        $row[3],   # Status
        $row[4],   # Reply
        $row[9],   # LTT
        $row[10],  # Last status
        $row[12],  # Comment
        $row[11]); # Time of status change
    }
    $sth->finish();
    
    # If a recursive mode is on walk deep in subfolders...
    if ($isRecursive)
    {
        $sth = $db->getFolderList($parent);
        while (@row = $sth->fetchrow_array)
        {
            drawHostField($row[0], $isRecursive);
        }
        $sth->finish();
    }
    return 1;
}
