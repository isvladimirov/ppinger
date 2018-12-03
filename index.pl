#!/usr/bin/env perl

#######################################
# PPinger
# Point of entrance
# Copyright 2018 duk3L3t0
#######################################

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

# Open output
my $ui = PDraw->new();

my $title = $config->val('Global', 'title');
my $refresh = 0;
my $action = $queryCGI->param('action');
my $editMode = 0;
switch ($action)
{
    case "edit"
    {
        # Draw main form with edit functions
        $action = "edit";
        $editMode = 1;
        $title = $title . " :: Configuration mode";
    }
    case "edit_folder"
    {
        $action = "edit_folder";
        $title = $title . " :: Edit folder";
    }
    case "edit_host"
    {
        $action = "edit_host";
        $title = $title . " :: Edit host";
    }
    else
    {
        # Draw main form
        $action = "view";
        $refresh = $config->val('Global', 'refresh');
    }
}

# Draw header
$ui->addHeader($title, $refresh);

$ui->openFolders($editMode);
my @row = ();
my $sth = $db->getFolderList(0);
for (my $i=1; $i <= $db->{ITEMS_COUNT}; $i++)
{
    @row = $sth->fetchrow_array;
    $ui->addFolder($editMode, $row[1], $row[0]);
}
$sth->finish();
$ui->closeFolders();

$ui->openHosts($editMode);

$sth = $db->getHostList(0);
for (my $i=1; $i <= $db->{ITEMS_COUNT}; $i++)
{
    @row = $sth->fetchrow_array;
    switch ($row[3])
    {
        case 1 { $row[3] = "unknown"; }
        case 2 { $row[3] = "alive"; }
        case 3 { $row[3] = "down"; }
        case 4 { $row[3] = "disabled"; }
    }
    $ui->addHost($editMode, $row[1], $row[0], $row[3], $ row[4], $row[9], $row[10], $row[12], $row[11]);
}
$sth->finish();
$ui->closeHosts();

$ui->addFooter("PPinger v0.2 | Разрабатываемая версия");

# Close database
$db->DESTROY;

1;
