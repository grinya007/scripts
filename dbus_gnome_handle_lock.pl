#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Carp::Assert;
use Net::DBus;
use Net::DBus::Reactor;

# locally
$ENV{DISPLAY} = ':0.0';

my $bOptOk = GetOptions
( 
    # pass code with caution
    'locked-code=s' => \my $sLockedCode,
    'unlocked-code=s' => \my $sUnlockedCode
);

assert($bOptOk && $sLockedCode && $sUnlockedCode, 'args ok');

my $rScreenSaver = Net::DBus->session()
    ->get_service('org.gnome.ScreenSaver')
    ->get_object('/org/gnome/ScreenSaver', 'org.gnome.ScreenSaver');

$rScreenSaver->connect_to_signal
(
    'ActiveChanged',
    sub
    {
        my ($bLocked) = @_;
        system($bLocked ? $sLockedCode : $sUnlockedCode) && die 'your code bad';
    }
);

Net::DBus::Reactor->main()->run();

exit 0;

