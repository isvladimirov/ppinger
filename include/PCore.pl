#!/usr/bin/env perl

use Switch;
use strict;

# List of available functions
sub drawFolderField; # Recursive function for drawing folder tree
sub drawHostField;   # Recursive function for drawing hosts

sub drawFolderField
{
    my ($sourceDB, $destinationUI, $parent, $level, $folderId, $editMode) = @_;
    my @row = ();
    my $sth = $sourceDB->getFolderList($parent);
    while (@row = $sth->fetchrow_array)
    {
        $destinationUI->addFolder($editMode, $row[1], $row[0], $level, 0, $folderId);
        drawFolderField($sourceDB, $destinationUI, $row[0], $level+1, $folderId, $editMode);
    }
    $sth->finish();
    return 1;
}

sub drawHostField
{
    my ($sourceDB, $destinationUI, $parent, $isRecursive, $editMode) = @_;
    my @row = ();
    if (($parent==0)&&($isRecursive))
    {
        $parent=-1;
    }
    my $sth = $sourceDB->getHostList($parent);
    
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
        $destinationUI->addHost($editMode, # Turn on edit mode
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
        $sth = $sourceDB->getFolderList($parent);
        while (@row = $sth->fetchrow_array)
        {
            drawHostField($sourceDB, $destinationUI, $row[0], $isRecursive, $editMode);
        }
        $sth->finish();
    }
    return 1;
}

1;
