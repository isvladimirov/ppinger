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
        my($self) = @_;
        return $dbh->disconnect;
    }

    # Returns ref to query hash. Use method 'fetchrow_array' to get next item.
    # Returns list of folders.
    sub getFolderList
    {
        my($self, $parent) = @_;
        my $query;
        if ($parent)
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
    # Returns list of hosts.
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

}
1;
