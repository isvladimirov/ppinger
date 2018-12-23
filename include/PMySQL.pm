#!/usr/bin/env perl

#######################################
# PPinger
# Class for accessing MySQL database
# Copyright 2018 duk3L3t0
#######################################
# Status values:
# 0 - show all (when it's posible)
# 1 - Unknown
# 2 - Alive
# 3 - Down
# 4 - Disabled

package PMySQL
{
    use DBI;
    use strict;

    my $dbh;

    sub new
    {
        my($class, $host, $user, $pass, $database) = @_;
        my $self = {
            name => 'PMySQL',
            version => '1.0',
            ITEMS_COUNT => 0,
            LAST_ERROR => '',
        };
        $dbh = DBI->connect("DBI:mysql:$database:$host", $user, $pass)
            or die "Can't connect to database";
        $dbh->{'mysql_enable_utf8'} = 1;
        $dbh->do('set names utf8');
        bless $self, $class;
        return $self;
    }

    sub DESTROY
    {
        return $dbh->disconnect;
    }

    # Returns ref to query hash. Use method 'fetchrow_array' to get next item.
    # Returns list of child folders in the $parent folder.
    # $parent=0 means all folders.
    sub getFolderList
    {
        my($self, $parent) = @_;
        my $query;
        if($parent)
        {
            # If a parent is set return its children only
            $query = "SELECT id,name FROM folders WHERE parent_id=$parent ORDER BY name;";
        }
        else
        {
            # If there is no parent return all folder
            $query = "SELECT id,name FROM folders ORDER BY name;";
        }
        my $queryHash = $dbh->prepare($query);
        $self->{ITEMS_COUNT} = $queryHash->execute;
        return $queryHash;
    }

    # Returns ref to query hash. Use method 'fetchrow_array' to get next item.
    # Returns list of hosts for a current folder.
    #
    # Usage: getHostList($parent, $status)
    #
    # If $parent doesn't set or equals '0' method returns all hosts.
    # The same for $status.
    #
    # Elemets of returned array:
    # 0 - id
    # 1 - host
    # 2 - parent_id
    # 3 - status
    # 4 - reply
    # 5 - method
    # 6 - port
    # 7 - attemps
    # 8 - timeout
    # 9 - last_test_time
    # 10 - last_status
    # 11 - status_changed
    # 12 - comment
    sub getHostList
    {
        my($self, $parent, $status) = @_;
        my $where = "";
        if ($parent) { $where = $where . " parent_id=$parent"; }
        if ( ($where) && ($status) ) { $where = $where . " and"; }
        if ($status) { $where = $where . " status=$status"; }
        if ($where) { $where = "WHERE" . $where; }
        my $query = "SELECT id,host,parent_id,status,reply,method,port,attempts,timeout,last_test_time,last_status,status_changed,comment FROM hosts $where ORDER BY host;";
        my $queryHash = $dbh->prepare($query);
        $self->{ITEMS_COUNT} = $queryHash->execute;
        return $queryHash;
    }

    # Returns number of items in last SQL query.
    sub getItemsCount
    {
        my($self) = @_;
        return $self->{ITEMS_COUNT};
    }
    
    # Returns last error
    sub getLastError
    {
        my($self) = @_;
        return $self->{LAST_ERROR};
    }
    
    # Returns name of a folder with $id.
    sub getFolderNameById
    {
        my($self, $id) = @_;
        my $queryHash = $dbh->prepare("SELECT name FROM folders WHERE id=$id;");
        $queryHash->execute;
        my @row = $queryHash->fetchrow_array();
        $queryHash->finish();
        return $row[0];
    }

    # Returns parent id of a folder with $id.
    sub getFolderParentById
    {
        my($self, $id) = @_;
        my $queryHash = $dbh->prepare("SELECT parent_id FROM folders WHERE id=$id;");
        $queryHash->execute;
        my @row = $queryHash->fetchrow_array();
        $queryHash->finish();
        return $row[0];
    }
    
    # Returns id of the folder by a given name
    sub getFolderIdByName
    {
        my($self, $name) = @_;
        my $queryHash = $dbh->prepare("SELECT id FROM folders WHERE name=$name;");
        $queryHash->execute;
        my @row = $queryHash->fetchrow_array();
        $queryHash->finish();
        $row[0] or $row[0]=0;
        return $row[0];
    }
    
    # Creates folder
    sub createFolder
    {
        my($self, $name, $parent) = @_;
        return $dbh->do("INSERT INTO folders (name, parent_id) VALUES ('$name', $parent);");
    }
    
    # Deletes folder with given ID
    sub deleteFolder
    {
        my($self, $id) = @_;
        return $dbh->do("DELETE FROM folders WHERE id=$id;");
    }
    
    # Updates folder
    sub updateFolder
    {
        my($self, $id, $name, $parentId) = @_;
        if (!($id =~ /^\d+?$/)) {$self->{LAST_ERROR}="Given Folder ID is not digital!"; return 0;}
        if (!($parentId =~ /^\d+?$/)) {$self->{LAST_ERROR}="Given Parent ID is not digital!"; return 0;}
        if ($id eq $parentId) {$self->{LAST_ERROR}="Cannot move folder to itself!"; return 0;}
        return $dbh->do("UPDATE folders SET name='$name', parent_id=$parentId WHERE id=$id;");
    }
}
1;
