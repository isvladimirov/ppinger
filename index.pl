#!/usr/bin/env perl

#######################################
# PPinger
# index.pl
# Point of entrance
# Copyright 2018 duk3L3t0
#######################################

#use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib 'include';
use PDraw;
use PMySQL;
use CGI qw(:standard);
use Config::IniFiles;
use Switch;
use strict;

use constant VERSION => 0.3;

# Recursive function for drawing folder tree
sub drawFolderField;

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

# Open output
my $ui = PDraw->new();

my $title = $config->val('Global', 'title');
my $refresh = 0;
my $action = $queryCGI->param('action');
my $folderId = $queryCGI->param('folder_id');
my $editMode = 0;
my $hash;

switch ($action)
{
    case "edit"
    {
        # Draw main form with edit functions
        $action = "edit";
        $editMode = 1;
        $title = $title . " :: Configuration mode";
    }
    case "edit_folder"
    {
        $action = "edit_folder";
        $editMode = 1;
        $title = $title . " :: Edit folder";
    }
    case "edit_host"
    {
        $action = "edit_host";
        $editMode = 1;
        $title = $title . " :: Edit host";
    }
    else
    {
        # Draw main form
        $action = "view";
        $refresh = $config->val('Global', 'refresh');
        $title .= " :: View mode";
    }
}

# Validate $folderId
$folderId =~ /^\d+?$/ or $folderId = 0;

# Draw header
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
        my $sth = $db->getHostList(0);
        for (my $i=1; $i <= $db->getItemsCount; $i++)
        {
            @row = $sth->fetchrow_array;
            switch ($row[3])
            {
                case 1 { $row[3] = "unknown"; }
                case 2 { $row[3] = "alive"; }
                case 3 { $row[3] = "down"; }
                case 4 { $row[3] = "disabled"; }
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
        $ui->closeHosts();
    }
}

# Draw footer
$ui->addFooter("PPinger v".(VERSION)." | Разрабатываемая версия");

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
