#!/usr/bin/env perl

#######################################
# PPinger
# PDraw.pm
# Class for drawing user interface
# Copyright 2018 duk3L3t0
#######################################
# Status values:
# 0 - Show all (when it's posible)
# 1 - Down
# 2 - Alive
# 3 - Unknown
# 4 - Disabled

package PDraw
{
    use Sys::Hostname;
    use POSIX qw(strftime);
    use Switch;
    use strict;
    use utf8;
    use CGI qw(-utf8);

    my %statusName = ( 1 => "Down",
                       2 => "Alive",
                       3 => "Unknown",
                       4 => "Disabled",
                     );

    sub new
    {
        my($class) = @_;
        my $self = {
            NAME => 'PDraw',
            VERSION => '1.0',
        };
        bless $self, $class;
        return $self;
    }

    sub addHeader
    {
        my($self, $title, $refresh, $cookie) = @_;
        my $queryCGI = CGI->new();
        if ($cookie)
        {
            print $queryCGI->header(-type=>"text/html;charset=UTF-8",-cookie=>$cookie);
        }
        else
        {
            print $queryCGI->header(-type=>"text/html;charset=UTF-8");
        }
        print "<!DOCTYPE html>\n";
        print "<html>\n";
        print "<head>\n";
        print "<meta charset='UTF-8'>\n";
        print "<title>$title</title>\n";
        print "<link href='share/style.css' rel='stylesheet'>\n";
        if ($refresh) { print "<meta http-equiv='refresh' content=$refresh>\n"; }
        print "</head>\n";
        print "<body>\n";
        print "<header id='pageHeader'>\n";
        print "<div id='pageHeaderLeft'>\n";
        print "$title<br>\n";
        print "Running on " . hostname() . "<br>\n";
        my $now_string = strftime "%a %e %b %Y %H:%M:%S", localtime;
        print "Page loaded at $now_string\n";
        print "</div>\n";
        print "<div id='pageHeaderRight'>\n";
        print "<a href='./index.pl?action=edit'><img width='32' src='share/edit-text-frame-update.svg' alt='Enter edit mode'></a>\n";
        print "</div>\n";
        print "</header>\n";
        return 1;
    }

    # Draws footer and closes html page
    sub addFooter
    {
        my($self, $status) = @_;
        print "<footer id='pageFooter'>$status</footer>\n";
        print "</body>\n";
        print "</html>\n";
        return 1;
    }

    sub openFolders
    {
        my($self, $need_edit) = @_;
        print "<nav id='pageNav'>\n";
        if ($need_edit)
        {
            print "<div id='folderHeader'>";
            # Link to create new folder
            print "<a href='./index.pl?action=edit_folder'>";
            print "<img width='16' src='share/fork.svg' alt='Add folder'></a>";
            print "<a href='./index.pl'>Folders</a></div>\n";
        }
        else
        {
            # Link to default page
            print "<div id='folderHeader'><a href='./index.pl'>Folders</a></div>\n";
        }
        print "<ul id='folderList'>\n";
        return 1;
    }

    sub addFolder
    {
        my($self, $need_edit, $name, $id, $level, $isLast, $checked_id) = @_;
        my $editButtons = "";
        my $prefix= "";
        for (my $i=0; $i<$level; $i++)
        {
            $prefix.="<img width='8' src='share/level.svg' alt=''>";
        }
        if ($prefix)
        {
            $prefix.="<img width='12' src='share/arrow-forward.svg' alt=''>";
        }
        if ($need_edit)
        {
            # Link to edit current folder
            $editButtons = "<a href='./index.pl?action=edit_folder&folder_id=$id'>";
            $editButtons .= "<img width='16' src='share/edit-text-frame-update.svg' alt='Edit this folder'></a>";
        }
        if ($id==$checked_id)
        {
            print "<li id='folderItemChecked'>$prefix";
        }
        else
        {
            print "<li id='folderItem'>$prefix";
        }
        print "<img width='16' src='share/folder-green.svg'>$editButtons";
        # Link to show current folder
        print "<a href='index.pl?folder_id=$id'>$name</a></li>\n";
        return 1;
    }

    sub closeFolders
    {
        my($self) = @_;
        print "</ul>\n";
        print "</nav>\n";
        return 1;
    }

    sub openHosts
    {
        my($self, $need_edit) = @_;
        print "<article id='pageHosts'>\n";
        print "<table id='mainTable'>\n";
        print "<tr id='mainTableHeader'>\n";
        if ($need_edit)
        {
            print "<th id='mainTableHeaderAdd'><a href='./index.pl?action=edit_host'>";
            print "<img width='16' src='share/fork.svg' alt='Edit this host'></a></th>\n";
        }
        print "<th id='mainTableHeaderHost'>Host</th>\n";
        print "<th id='mainTableHeaderStatus'>Status</th>\n";
        print "<th id='mainTableHeaderReply'>Reply</th>\n";
        print "<th id='mainTableHeaderLTT'>Last Test Time</th>\n";
        print "<th id='mainTableHeaderLS'>Last Status</th>\n";
        print "<th id='mainTableHeaderCom'>Comment</th>\n";
        print "<th id='mainTableHeaderSC'>Status Changed</th>\n";
        print "</tr>\n";
        return 1;
    }

    sub addHost
    {
        my($self, $need_edit, $name, $id, $status, $reply, $ltt, $lastStatus, $comment, $statusChanged) = @_;
        my $tableRowId = "mainTableRow";
        switch ($status)
        {
            case "down" { $tableRowId = "mainTableRowBad"; }
            case "disabled" { $tableRowId = "mainTableRowDisabled"; }
            case "unknown" { $tableRowId = "mainTableRowUnknown"; }
        }
        print "<tr id='$tableRowId'>\n";
        if ($need_edit)
        {
            print "<td><a href='./index.pl?action=edit_host&host_id=$id'>";
            print "<img width='16' src='share/edit-text-frame-update.svg' alt='Edit this host'>";
            print "</a></td>\n";
        }
        print "<td id='mainTableDataHost'><a href='./index.pl?action=show_host&host_id=$id'>$name</a></td>\n";
        print "<td>$status</td>\n";
        print "<td>$reply ms</td>\n";
        print "<td>$ltt</td>\n";
        print "<td>$lastStatus</td>\n";
        print "<td id='mainTableComment'>$comment</td>\n";
        print "<td>$statusChanged</td>\n";
        print "</tr>\n";
        return 1;
    }
    
    sub addHostSeparator
    {
        my($self, $title) = @_;
        print "<tr id='mainTableSeparator'>";
        print "<td colspan='8'>$title</td>";
        print "</tr>\n";
        return 1;
    }

    sub closeHosts
    {
        print "</table>\n";
        print "</article>\n";
        return 1;
    }
    
    # Draws folder edit form
    sub editFolder
    {
        my($self, $id, $name, $parentId, $foldersHash) = @_;
        my @row = ();
        $id or $id="New";
        print "<article id='pageHosts'>\n";
        print "<h1>Edit folder</h1>\n";
        print "<form action='./write.pl' method='post'>\n";
        print "<table id='formEdit'>\n";
        print "<tr><td>Folder name:</td><td><input name='name' type='text' value='$name'></td></tr>\n";
        print "<tr><td>Folder ID:</td><td>$id</td></tr>\n";
        print "<tr><td>Folder parent:</td>\n";
        print "<td><select name='parent_id'>\n";
        print "<option value='-1'>Root</option>\n";
        while (@row = $foldersHash->fetchrow_array())
        {
            if($parentId==$row[0])
            {
                print "<option selected value='$row[0]'>$row[1]</option>\n";
            }
            elsif($id!=$row[0])
            {
                print "<option value='$row[0]'>$row[1]</option>\n";
            }
        }
        print "</select></td></tr>\n";
        if ($id!="New")
        {
            print "<tr><td>Delete (with children):</td>\n";
            print "<td><input type='checkbox' name='delete' value='folder'></td></tr>\n";
        }
        print "<tr><td align='right' colspan='2'><input type='submit' value='Save'>\n";
        print "<input type='button' value='Cancel' onclick='window.history.back()' /></td></tr>\n";
        print "</table>\n";
        print "<input type='hidden' name='folder_id' value='$id'>\n";
        print "</form>\n";
        print "</article>\n";
        return 1;
    }
    
    # Draws host edit form
    sub editHost
    {
        my($self, $foldersHash, %host) = @_;
        $host{"id"} or $host{"id"} = "New";
        $host{"attempts"} or $host{"attempts"} = 2;
        $host{"timeout"} or $host{"timeout"} = 200;
        $host{"comment"} or $host{"comment"} = "";
        print "<article id='pageHosts'>\n";
        print "<h1>Edit host</h1>\n";
        print "<form action='./write.pl' method='post'>\n";
        print "<table id='formEdit'>\n";
        print "<tr><td>Host name:</td><td><input name='host' type='text' value='".$host{"host"}."'></td></tr>\n";
        print "<tr><td>Host ID:</td><td>".$host{"id"}."</td></tr>\n";
        print "<tr><td>Parent:</td>\n";
        print "<td><select name='parent_id'>\n";
        print "<option value='-1'>Root</option>\n";
        my @row = ();
        while (@row = $foldersHash->fetchrow_array())
        {
            if($host{"parentId"}==$row[0])
            {
                print "<option selected value='$row[0]'>$row[1]</option>\n";
            }
            else
            {
                print "<option value='$row[0]'>$row[1]</option>\n";
            }
        }
        print "</select></td></tr>\n";
        print "<tr><td>Method:</td><td><select name='method'>\n";
        if ($host{"method"} eq "ping")
        {
            print "<option selected value='ping'>Ping</option>\n";
        }
        else
        {
            print "<option value='ping'>Ping</option>\n";
        }
        if ($host{"method"} eq "tcp")
        {
            print "<option selected value='tcp'>TCP</option>\n";
        }
        else
        {
            print "<option value='tcp'>TCP</option>\n";
        }
        if ($host{"method"} eq "udp")
        {
            print "<option selected value='udp'>UDP</option>\n";
        }
        else
        {
            print "<option value='udp'>UDP</option>\n";
        }
        if ($host{"method"} eq "external")
        {
            print "<option selected value='external'>External</option>\n";
        }
        else
        {
            print "<option value='external'>External</option>\n";
        }
        print "</select></td></tr>\n";
        print "<tr><td>Port:</td><td><input name='port' type='text' value='".$host{"port"}."'></td></tr>\n";
        print "<tr><td>Attempts:</td><td><input name='attempts' type='text' value='".$host{"attempts"}."'></td></tr>\n";
        print "<tr><td>Timeout:</td><td><input name='timeout' type='text' value='".$host{"timeout"}."'></td></tr>\n";
        print "<tr><td>Comment:</td><td><input name='comment' type='text' value='".$host{"comment"}."'></td></tr>\n";
        print "<tr><td>Disabled:</td>\n";
        if($host{"status"}==4)
        {
            print "<td><input type='checkbox' checked name='host_disable' value='1'></td></tr>\n";
        }
        else
        {
            print "<td><input type='checkbox' name='host_disable' value='1'></td></tr>\n";
        }
        print "<tr><td>External script:</td><td><input name='command' type='text' value='".$host{"command"}."'></td></tr>\n";
        if ($host{"id"}!="New")
        {
            print "<tr><td>Delete this host:</td>\n";
            print "<td><input type='checkbox' name='delete' value='host'></td></tr>\n";
        }
        print "<tr><td align='right' colspan='2'><input type='submit' value='Save'>\n";
        print "<input type='button' value='Cancel' onclick='window.history.back()' /></td></tr>\n";
        print "</table>\n";
        print "<input type='hidden' name='host_id' value='".$host{"id"}."'>\n";
        print "</form>\n";
        print "</article>\n";
        return 1;
    }

    # Shows host details
    sub showHost
    {
        my($self, $logs, %host) = @_;
        my %liID = ( 1 => "statusDown",
                     2 => "statusAlive",
                     3 => "statusUnknown",
                     4 => "statusDisabled",
                   );
        $host{"command"} or $host{"command"}="None set";
        print "<article id='pageHosts'>\n";
        print "<h1>Host details</h1>\n";
        print "<div id='showHostWholeBlock'>\n";
        print "<div id='showHostBlock'>\n";
        print "<div id='showHostBlockHeader'>General information</div>\n";
        print "<ul id='showHostBlock'>\n";
        print "<li>Hostname: ".$host{"host"}."</li>\n";
        print "<li>ID: ".$host{"id"}."</li>\n";
        print "<li>Comment: ".$host{"comment"}."</li>\n";
        print "</ul>\n</div>\n";
        print "<div id='showHostBlock'>\n";
        print "<div id='showHostBlockHeader'>Test properties</div>\n";
        print "<ul id='showHostBlock'>\n";
        print "<li>Test type: ".$host{"method"}."</li>\n";
        print "<li>Port: ".$host{"port"}."</li>\n";
        print "<li>External script: ".$host{"command"}."</li>\n";
        print "<li>Attempts: ".$host{"attempts"}."</li>\n";
        print "<li>Timeout: ".$host{"timeout"}." ms</li>\n";
        print "</ul>\n</div>\n";
        print "<div id='showHostBlock'>\n";
        print "<div id='showHostBlockHeader'>Status</div>\n";
        print "<ul id='showHostBlock'>\n";
        print "<li>Current status: ".$statusName{$host{"status"}}."</li>\n";
        print "<li>Last status change: ".$host{"statusChanged"}."</li>\n";
        print "</ul>\n</div>\n";
        print "<div id='showHostBlock'>\n";
        print "<div id='showHostBlockHeader'>Last events</div>\n";
        print "<ul id='showHostBlock'>\n";
        my @row = ();
        while (@row = $logs->fetchrow_array())
        {
            print "<li id='".$liID{$row[1]}."'>Status ".$statusName{$row[1]}." set at $row[2]</li>\n";
        }
        print "</ul>\n</div>\n";
        print "</div>\n";
        print "</article>\n";
        return 1;
    }
}
1;
