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

    Draws footer and closes html page
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
        print "</table>\n";
        print "</article>\n";
        return 1;
    }
    
    # Draws folder edit form
    sub editFolder
    {
        my($self, $id, $name, $parentId) = @_;
        $id or $id="New";
        print "<article id='pageHosts'>\n";
        print "<h1>Edit folder</h1>\n";
        print "<form action='./write.pl?folder_id=$id' method='post'>\n";
        print "<table id='formEditFolder'>\n";
        print "<tr><td>Folder name:</td><td><input type='text' value='$name'></td></tr>\n";
        print "<tr><td>Folder ID:</td><td>$id</td></tr>\n";
        print "<tr><td>Folder parent:</td>\n";
        print "<td><select name='new_parent_name'>\n";
        print "<option>Example parent</option>\n";
        print "</select></td><tr>\n";
        print "<tr><td align='right' colspan='2'><input type='submit' value='Save'>\n";
        print "<input type='button' value='Cancel'></td></tr>\n";
        print "</table>\n</form>\n";
        print "</article>\n";
        return 1;
    }
}
1;
