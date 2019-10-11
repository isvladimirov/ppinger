#!/usr/bin/env perl

#############################################################################
#
#    PCore.pl - Web core library
#    Copyright (C) 2018-2019 Igor Vladimirov <luiseal.mail@gmail.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see http://www.gnu.org/licenses/
#
#############################################################################

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
    my %hostStatus = ();
    my @row = ();
    my $separatorText;
    if (($parent==0)&&($isRecursive))
    {
        $parent=-1;
    }

    if ( $sourceDB->countHostStatus($showStatus, $parent) )
        {
            $separatorText = $sourceDB->getPath($parent);
            %hostStatus = ( "down"    => $sourceDB->countHostStatus(STATUS_DOWN, $parent),
                            "alive"   => $sourceDB->countHostStatus(STATUS_ALIVE, $parent),
                            "unknown" => $sourceDB->countHostStatus(STATUS_UNKNOWN, $parent),
                          );
            $separatorText .= " (".$hostStatus{"alive"};
            $separatorText .= "/".$hostStatus{"down"};
            $separatorText .= "/".$hostStatus{"unknown"}.")";
            $destinationUI->addHostSeparator($separatorText);
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
            drawHostField($sourceDB, $destinationUI, $row[0], $isRecursive, $editMode, $showStatus);
        }
        $sth->finish();
    }
    return 1;
}

1;
