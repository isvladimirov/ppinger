#!/usr/bin/env perl

#######################################
# PPinger
# PCore.pl
# Web core library
# Copyright 2018-2019 duk3L3t0
#######################################

use Switch;
use strict;
use constant
{
    STATUS_ALL => 0,
    STATUS_DOWN => 1,
    STATUS_ALIVE => 2,
    STATUS_UNKNOWN => 3,
    STATUS_DISABLED => 4,
};

# List of available functions
sub drawFolderField; # Recursive function for drawing folder tree
sub drawHostField;   # Recursive function for drawing hosts

my %statusName = ( 1 => "down",
                   2 => "alive",
                   3 => "unknown",
                   4 => "disabled",
                 );

sub drawFolderField
{
    my ($sourceDB, $destinationUI, $parent, $level, $folderId, $editMode) = @_;
    my %hostStatus = ();
    my $folderStatus;
    my @row = ();
    my $sth = $sourceDB->getFolderList($parent);
    while (@row = $sth->fetchrow_array)
    {
        %hostStatus = ( "down"    => $sourceDB->countHostStatus(STATUS_DOWN, $row[0]),
                        "alive"   => $sourceDB->countHostStatus(STATUS_ALIVE, $row[0]),
                        "unknown" => $sourceDB->countHostStatus(STATUS_UNKNOWN, $row[0]),
                      );
        $row[1] .= " (".$hostStatus{"alive"};
        $row[1] .= "/".$hostStatus{"down"};
        $row[1] .= "/".$hostStatus{"unknown"}.")";
        if ($hostStatus{"down"}>0) { $folderStatus = 1; }
        else { undef $folderStatus; }
        $destinationUI->addFolder($editMode,      # '1' - edit mode is on
                                  $row[1],        # Folder name
                                  $row[0],        # Folder ID
                                  $level,         # Folder level
                                  0,              # Is this folder last. Doesn't use.
                                  $folderId,      # ID of current folder
                                  $folderStatus); # Status of hosts in folder
        drawFolderField($sourceDB, $destinationUI, $row[0], $level+1, $folderId, $editMode);
    }
    $sth->finish();
    return 1;
}

sub drawHostField
{
    my ($sourceDB, $destinationUI, $parent, $isRecursive, $editMode, $showStatus) = @_;
    if ($showStatus) { $isRecursive = 0; } # Cannot use Recursive Mode when in Status Mode
    my %hostStatus = ();
    my @row = ();
    if (($parent==0)&&($isRecursive))
    {
        $parent=-1;
    }
    my $sth = $sourceDB->getHostList($parent, $showStatus);
    
    # Draw hosts located in the current folder
    while (@row = $sth->fetchrow_array)
    {
        $destinationUI->addHost($editMode, # Turn on edit mode
        $row[1],                           # Hostname
        $row[0],                           # Host ID
        $statusName{$row[3]},              # Status
        $row[4],                           # Reply
        $row[9],                           # LTT
        $statusName{$row[10]},             # Last status
        $row[12],                          # Comment
        $row[11]);                         # Time of status change
    }
    $sth->finish();
    
    # If a recursive mode is on walk deep in subfolders...
    if ($isRecursive)
    {
        $sth = $sourceDB->getFolderList($parent);
        while (@row = $sth->fetchrow_array)
        {
            %hostStatus = ( "down"    => $sourceDB->countHostStatus(STATUS_DOWN, $row[0]),
                            "alive"   => $sourceDB->countHostStatus(STATUS_ALIVE, $row[0]),
                            "unknown" => $sourceDB->countHostStatus(STATUS_UNKNOWN, $row[0]),
                           );
            $row[1] .= " (".$hostStatus{"alive"};
            $row[1] .= "/".$hostStatus{"down"};
            $row[1] .= "/".$hostStatus{"unknown"}.")";   
            $destinationUI->addHostSeparator($row[1]);
            drawHostField($sourceDB, $destinationUI, $row[0], $isRecursive, $editMode);
        }
        $sth->finish();
    }
    return 1;
}

1;
