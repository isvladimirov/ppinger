#!/usr/bin/env perl

#######################################
# PPinger
# write.pl
# Script for updating database
# Copyright 2018 duk3L3t0
#######################################

#use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use lib 'include';
use PDraw;
use PMySQL;
use CGI qw(:standard);
use Config::IniFiles;
use Switch;
use strict;

my $config = Config::IniFiles->new( -file => "etc/ppinger.cfg" );
my $queryCGI = CGI->new();
# Try to open database
my $db = PMySQL->new(
    $config->val('SQL', 'db_host'),
    $config->val('SQL', 'db_user'),
    $config->val('SQL', 'db_pass'),
    $config->val('SQL', 'db_name')
);

my $folderId = $queryCGI->param('folder_id');
my $folderName = $queryCGI->param('name');
my $parentId = $queryCGI->param('parent_id');
my $deleteObject = $queryCGI->param('delete');
my $output="Content-type: text/html\n\n";
$output.="<html>\n<head>\n";
$output.="<meta http-equiv='refresh' content='3;url=./index.pl'>\n";
$output.="</head>\n";
$output.="<body>\n";

if ($folderId eq 'New')
{
    $output.="Create new folder ";
    $db->createFolder($folderName, $parentId);
}
elsif ($deleteObject eq 'folder')
{
    $output.="Delete folder ";
    $db->deleteFolder($folderId);
}
elsif ($folderId =~ /^\d+?$/)
{
    $output.="Update folder ";
    $db->updateFolder($folderId, $folderName, $parentId);
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
