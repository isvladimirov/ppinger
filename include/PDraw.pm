#!/usr/bin/env perl

#######################################
# PPinger
# Class for drawing user interface
# Copyright 2018 duk3L3t0
#######################################
# Status values:
# 0 - Show all (when it's posible)
# 1 - Unknown
# 2 - Alive
# 3 - Down
# 4 - Disabled

package PDraw
{
    use Sys::Hostname;
    use POSIX qw(strftime);
    use Switch;
    use strict;
    
    sub new
    {
        my($class) = @_;
        my $self = {
            name => 'PDraw',
            version => '1.0',
        };
        bless $self, $class;
        return $self;
    }
    
    sub addHeader
    {
        my($self, $title, $refresh) = @_;
        print "Content-type: text/html\n\n";
        print "<!DOCTYPE html>\n";
        print "<html>\n";
        print "<head>\n";
        print "<meta charset='UTF-8'>\n";
        print "<title>$title</title>\n";
        print "<link href='share/style.css' rel='stylesheet'>\n";
        if ($refresh) { print "<meta http-equiv='refresh' content=$refresh>\n"; }
        print "</head>\n";
        print "<body>\n";
        print "<header id='pageHeader'>$title<br>\n";
        print "Running on " . hostname() . "<br>\n";
        my $now_string = strftime "%a %e %b %Y %H:%M:%S", localtime;
        print "Page loaded at $now_string</header>\n";
        return 1;
    }
    
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
            print "<div id='folderHeader'><img width='16' src='share/fork.svg'> Folders</div>\n";
        }
        else
        {
            print "<div id='folderHeader'>Folders</div>\n";
        }
        print "<ul id='folderList'>\n";
        return 1;
    }
    
    sub addFolder
    {
        my($self, $need_edit, $name, $id) = @_;
        my $editButtons = "";
        if ($need_edit)
        {
            $editButtons = " <img width='16' src='share/edit-text-frame-update.svg'>";
        }
        print "<li id='folderItem'><img width='16' src='share/folder-green.svg'>$editButtons $name</li>\n";
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
        print "<tr id='mainTableHeader'>";
        if ($need_edit)
        {
            print "<th id='mainTableHeaderAdd'><img width='16' src='share/fork.svg'></th>"
        }
        print "<th id='mainTableHeaderHost'>Host</th>";
        print "<th id='mainTableHeaderStatus'>Status</th>";
        print "<th id='mainTableHeaderReply'>Reply</th>";
        print "<th id='mainTableHeaderLTT'>Last Test Time</th>";
        print "<th id='mainTableHeaderLS'>Last Status</th>";
        print "<th id='mainTableHeaderCom'>Comment</th>";
        print "<th id='mainTableHeaderSC'>Status Changed</th>";
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
        }
        print "<tr id='$tableRowId'>";
        if ($need_edit)
        {
            print "<td id='$tableRowId'><img width='16' src='share/edit-text-frame-update.svg'></td>"
        }
        print "<td id='mainTableDataHost'>$name</td>";
        print "<td>$status</td>";
        print "<td>$reply ms</td>";
        print "<td>$ltt</td>";
        print "<td>unknown</td>";
        print "<td id='mainTableComment'>$comment</td>";
        print "<td>$statusChanged</td>";
        print "<tr>\n";
        return 1;
    }
    
    sub closeHosts
    {
        #my($self) = @_;
        print "</table>\n";
        print "</article>\n";
        return 1;
    }
}
1;
