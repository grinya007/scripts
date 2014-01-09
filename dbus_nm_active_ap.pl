#!/usr/bin/perl
use strict;
use warnings;
use Net::DBus;

use Data::Dumper;

# locally
$ENV{DISPLAY} = ':0.0';

my $rNM = Net::DBus->system()
    ->get_service('org.freedesktop.NetworkManager');
my $sWlan0 = $rNM
    ->get_object('/org/freedesktop/NetworkManager', 'org.freedesktop.NetworkManager')
    ->GetDeviceByIpIface('wlan0');
my $rWlan0 = $rNM
    ->get_object($sWlan0, 'org.freedesktop.NetworkManager.Device.Wireless');
my $rAP = $rNM
    ->get_object($rWlan0->ActiveAccessPoint(), 'org.freedesktop.NetworkManager.AccessPoint');

print join('', map {chr($_)} @{ $rAP->Ssid() });

exit 0;

