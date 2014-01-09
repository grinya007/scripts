#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Carp::Assert;
use Net::DBus;

# locally
$ENV{DISPLAY} = ':0.0';

my $bOptOk = GetOptions
(
    'lock' => \my $bLock,
    'unlock' => \my $bUnLock
);

assert($bOptOk && scalar(grep {$_} ($bLock, $bUnLock)) == 1, 'args ok');

my $rScreenSaver = Net::DBus->session()
    ->get_service('org.gnome.ScreenSaver')
    ->get_object('/org/gnome/ScreenSaver', 'org.gnome.ScreenSaver');
my $bLocked = $rScreenSaver->GetActive();
if ($bLock && !$bLocked)
{
    $rScreenSaver->Lock();
}
elsif ($bUnLock && $bLocked)
{
    $rScreenSaver->SetActive(0);
}

exit 0;

