#!/usr/bin/env perl

#######################################
# PPinger
# write.pl
# Script for updating database
# Copyright 2018-2019 duk3L3t0
#######################################

#use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib "../include";
use PMySQL;
use CGI qw(:standard);
use CGI::Session qw(-ip-match);
use Config::IniFiles;
use Switch;
use strict;

my $queryCGI = CGI->new();
### Authorization ###
my $session;
if ( $queryCGI->cookie('SESSION_ID') )
{
    $session = new CGI::Session("driver:File", $queryCGI->cookie('SESSION_ID'), {Directory=>"/tmp"});
    if ( $session->id() ne $queryCGI->cookie('SESSION_ID') )
    {
        ### Authorization failed ###
        $session->delete();
        print $queryCGI->redirect("auth.pl");
        return 1;
    }
}
else
{
    # Authorization failed
    print $queryCGI->redirect("auth.pl");
    return 1;
}
### Authorization verified ###
$session->expire('+1h');
my $config = Config::IniFiles->new( -file => "../etc/ppinger.cfg" );
# Try to open database
my $db = PMySQL->new(
    $config->val('SQL', 'db_host'),
    $config->val('SQL', 'db_user'),
    $config->val('SQL', 'db_pass'),
    $config->val('SQL', 'db_name')
);

my $folderId = $queryCGI->param('folder_id');
my %host = ( 'id' => $queryCGI->param('host_id') );
my $deleteObject = $queryCGI->param('delete');
my $output="Content-type: text/html\n\n";
$output.="<html>\n<head>\n";
$output.="<meta http-equiv='refresh' content='2;url=./index.pl'>\n";
$output.="</head>\n";
$output.="<body>\n";

if ($folderId eq 'New')
{
    $output.="Create new folder ";
    $db->createFolder($queryCGI->param('name'), $queryCGI->param('parent_id'));
}
elsif ($deleteObject eq 'folder')
{
    $output.="Delete folder ";
    $db->deleteFolder($folderId);
}
elsif ($folderId =~ /^\d+?$/)
{
    $output.="Folder update ";
    $db->updateFolder($folderId, $queryCGI->param('name'), $queryCGI->param('parent_id'));
}
elsif ($host{"id"} eq 'New')
{
    $output.="Create new host ";
    $host{"host"} = $queryCGI->param('host');
    $host{"parentId"} = $queryCGI->param('parent_id');
    $host{"method"} = $queryCGI->param('method');
    $host{"port"} = $queryCGI->param('port');
    $host{"attempts"} = $queryCGI->param('attempts');
    $host{"timeout"} = $queryCGI->param('timeout');
    $host{"comment"} = $queryCGI->param('comment');
    if ($queryCGI->param('host_disable')) {$host{"status"} = 4;}
    else {$host{"status"} = 3;}
    $db->createHost(%host);
}
elsif ($deleteObject eq 'host')
{
    $output.="Delete host ";
    $db->deleteHost($host{"id"});
}
elsif ($host{"id"} =~ /^\d+?$/)
{
    $output.="Host update ";
    $host{"host"} = $queryCGI->param('host');
    $host{"parentId"} = $queryCGI->param('parent_id');
    $host{"method"} = $queryCGI->param('method');
    $host{"port"} = $queryCGI->param('port');
    $host{"attempts"} = $queryCGI->param('attempts');
    $host{"timeout"} = $queryCGI->param('timeout');
    $host{"comment"} = $queryCGI->param('comment');
    $host{"command"} = $queryCGI->param('command');
    if ($queryCGI->param('host_disable')) {$host{"status"} = 4;}
    else {$host{"status"} = 3;}
    $db->updateHost(%host);
}
else
{
    $output.="Nothing to do here ";
}
if ($db->getLastError())
{
    $output.="done with some errors!<br />\n";
    $output.=$db->getLastError()."<br />\n";
}
else
{
    $output.="done with no errors.<br />\n";
}
$output.="</body>\n</html>\n";
# Close database
$db->DESTROY();

# Print message and exit
print $output;

# End of main function
1;
