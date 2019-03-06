#!/usr/bin/env perl

#######################################
# PPinger
# PMySQL.pm
# Class for accessing MySQL database
# Copyright 2018-2019 duk3L3t0
#######################################
# Status values:
# 0 - show all (when it's posible)
# 1 - Down
# 2 - Alive
# 3 - Unknown
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
            NAME => 'PMySQL',
            VERSION => '1.0',
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
    # 13 - command
    sub getHostList
    {
        my($self, $parent, $status) = @_;
        my $where = "";
        if ($parent) { $where = $where . " parent_id=$parent"; }
        if ( ($where) && ($status) ) { $where = $where . " and"; }
        if ($status) { $where = $where . " status=$status"; }
        if ($where) { $where = "WHERE" . $where; }
        my $query = "SELECT id,host,parent_id,status,reply,method,port,attempts,timeout,last_test_time,last_status,status_changed,comment,command FROM hosts $where ORDER BY status, host;";
        my $queryHash = $dbh->prepare($query);
        $self->{ITEMS_COUNT} = $queryHash->execute;
        return $queryHash;
    }

    # Returns named hash of a host object
    sub getHostById
    {
        my($self, $id) = @_;
        my $query = "SELECT host,parent_id,status,reply,method,port,attempts,timeout,last_test_time,last_status,status_changed,comment,command FROM hosts WHERE id=$id;";
        my $queryHash = $dbh->prepare($query);
        $self->{ITEMS_COUNT} = $queryHash->execute;
        my @row = $queryHash->fetchrow_array();
        $queryHash->finish;
        my %host = ('id' => $id,
                    'host' => $row[0],
                    'parentId' => $row[1],
                    'status' => $row[2],
                    'reply' => $row[3],
                    'method' => $row[4],
                    'port' => $row[5],
                    'attempts' => $row[6],
                    'timeout' => $row[7],
                    'lastTestTime' => $row[8],
                    'lastStatus' => $row[9],
                    'statusChanged' => $row[10],
                    'comment' => $row[11],
                    'command' => $row[12]);
        return %host;
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
        my $queryHash = $dbh->prepare("SELECT id FROM folders WHERE name='$name';");
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
        # This method must be rewrited. It should delete all subfolders and children as well.
        if ($id<1) {$self->{LAST_ERROR}="Cannot remove system folder!"; return 0;}
        # Delete hosts in a given folder
        $dbh->do("DELETE FROM hosts WHERE parent_id=$id;");
        # Delete folder
        $dbh->do("DELETE FROM folders WHERE id=$id;");
        # Check for subfolders
        my $sth = $self->getFolderList($id);
        my @row = ();
        while (@row = $sth->fetchrow_array)
        {
            $self->deleteFolder($row[0]);
        }
        $sth->finish();
        return 1;
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
    
    # Returns name of a host with $id.
    sub getHostNameById
    {
        my($self, $id) = @_;
        my $queryHash = $dbh->prepare("SELECT host FROM hosts WHERE id=$id;");
        $queryHash->execute;
        my @row = $queryHash->fetchrow_array();
        $queryHash->finish();
        return $row[0];
    }

    # Returns parent id of a host with $id.
    sub getHostParentById
    {
        my($self, $id) = @_;
        my $queryHash = $dbh->prepare("SELECT parent_id FROM hosts WHERE id=$id;");
        $queryHash->execute;
        my @row = $queryHash->fetchrow_array();
        $queryHash->finish();
        return $row[0];
    }
    
    # Returns id of the host by a given name
    sub getHostIdByName
    {
        my($self, $name) = @_;
        my $queryHash = $dbh->prepare("SELECT id FROM hosts WHERE name=$name;");
        $queryHash->execute;
        my @row = $queryHash->fetchrow_array();
        $queryHash->finish();
        $row[0] or $row[0]=0;
        return $row[0];
    }
    
    # Returns id of the host by a given name
    sub getHostCommentById
    {
        my($self, $id) = @_;
        my $queryHash = $dbh->prepare("SELECT comment FROM hosts WHERE id=$id;");
        $queryHash->execute;
        my @row = $queryHash->fetchrow_array();
        $queryHash->finish();
        $row[0] or $row[0]=0;
        return $row[0];
    }
    
    # Creates a host
    sub createHost
    {
        my($self, %host) = @_;
        if ( !($host{"host"}) ) {$self->{LAST_ERROR} = "Hostname cannot be empty!"; return 0;}
        if ( !($host{"parentId"} =~ /^\d+?$/) ) {$host{"parentId"}=-1;}
        if ( ($host{"status"} < 1) || ($host{"status"} > 4) ) {$host{"status"} = 3;}
        $host{"method"} or $host{"method"} = "ping";
        if ( ($host{"port"} < 1) || ($host{"port"} > 65535) ) {$host{"port"}=1;}
        if ( !($host{"attempts"} =~ /^\d+?$/) ) {$host{"attempts"}=2;}
        if ( !($host{"timeout"} =~ /^\d+?$/) ) {$host{"timeout"}=200;}
        my $query = "INSERT INTO hosts (host, parent_id, status, method, port, attempts, timeout, comment) ";
        $query .= "VALUES ('".$host{"host"}."', ".$host{"parentId"}.", ".$host{"status"}.", '".$host{"method"}."', ";
        $query .= $host{"port"}.", ".$host{"attempts"}.", ".$host{"timeout"}.", '".$host{"comment"}."');";
        return $dbh->do($query);
    }
    
    # Deletes a host
    sub deleteHost
    {
        my($self, $id) = @_;
        return $dbh->do("DELETE FROM hosts WHERE id=$id;");
    }

    # Updates a host
    sub updateHost
    {
        my($self, %host) = @_;
        if ( !($host{"id"} =~ /^\d+?$/) ) {$self->{LAST_ERROR} = "Host ID must be digital!"; return 0;}
        if ( !($host{"host"}) ) {$self->{LAST_ERROR} = "Hostname cannot be empty!"; return 0;}
        if ( !($host{"parentId"} =~ /^\d+?$/) ) {$host{"parentId"}=-1;}
        if ( ($host{"status"} < 1) || ($host{"status"} > 4) ) {$host{"status"} = 3;}
        $host{"method"} or $host{"method"} = "ping";
        if ( ($host{"port"} < 1) || ($host{"port"} > 65535) ) {$host{"port"}=1;}
        if ( !($host{"attempts"} =~ /^\d+?$/) ) {$host{"attempts"}=2;}
        if ( !($host{"timeout"} =~ /^\d+?$/) ) {$host{"timeout"}=200;}
        my $query = "UPDATE hosts SET ";
        $query .= "host = '".$host{"host"}."', ";
        $query .= "parent_id = ".$host{"parentId"}.", ";
        $query .= "status = ".$host{"status"}.", ";
        $query .= "method = '".$host{"method"}."', ";
        $query .= "port = ".$host{"port"}.", ";
        $query .= "attempts = ".$host{"attempts"}.", ";
        $query .= "timeout = ".$host{"timeout"}.", ";
        $query .= "comment = '".$host{"comment"}."', ";
        $query .= "command = '".$host{"command"}."', ";
        $query .= "status_changed=now() ";
        $query .= "WHERE id=".$host{"id"}.";";
        return $dbh->do($query);
    }

    # Updates status of a host
    sub updateHostStatus
    {
        my($self, $id, $status, $reply, $limit) = @_;
        my $queryHash = $dbh->prepare("SELECT status FROM hosts WHERE id=$id;");
        $queryHash->execute();
        my @row = $queryHash->fetchrow_array();
        my $query = "UPDATE hosts SET ";
        if ( ($row[0])!=($status) )
        {
            $self->insertLog($id, $status, $limit);
            $query .= "last_status=$row[0], ";
            $query .= "status_changed=now(), ";
            $query .= "status=$status, ";
        }
        if ($reply) {$query .= "reply=$reply, ";}
        $query .= "last_test_time=now() ";
        $query .= "WHERE id=$id;";
        return $dbh->do($query);
    }

    # Returns a hash of host logs list
    sub getHostLogs
    {
        my($self, $id) = @_;
        my $query = "SELECT id,status,time,host_id FROM logs ORDER BY time DESC LIMIT 100;";
        if ($id) { $query = "SELECT id,status,time FROM logs WHERE host_id=$id ORDER BY time DESC;"; }
        my $queryHash = $dbh->prepare($query);
        $self->{ITEMS_COUNT} = $queryHash->execute;
        return $queryHash;
    }

    # Inserts event in logs
    sub insertLog
    {
        my($self, $id, $status, $limit) = @_;
        $limit or $limit = 5;
        my $queryHash = $dbh->prepare("SELECT count(*) FROM logs WHERE host_id=$id;");
        $queryHash->execute();
        my @row = $queryHash->fetchrow_array();
        if ( $row[0]>$limit )
        {
            $limit = $row[0] - $limit + 1;
            $dbh->do("DELETE FROM logs WHERE host_id=$id ORDER BY time LIMIT $limit");
        }
        return $dbh->do("INSERT INTO logs set host_id=$id, status=$status;");
    }

    # Clears logs of a host
    sub deleteLogs
    {
        my($self, $id) = @_;
        return $dbh->do("DELETE FROM logs WHERE id=$id;");
    }

    # Returns count of host with given status in a folder ('0' means all folders)
    sub countHostStatus
    {
        my($self, $status, $parent) = @_;
        my $query="SELECT count(*) FROM hosts;";
        if ( $status ) { $query = "SELECT count(*) FROM hosts WHERE status=$status;"; }
        if ( $status && $parent ) { $query = "SELECT count(*) FROM hosts WHERE status=$status AND parent_id=$parent;"; }
        my $queryHash = $dbh->prepare($query);
        $queryHash->execute();
        my @row = $queryHash->fetchrow_array();
        return $row[0];
    }
}
1;
