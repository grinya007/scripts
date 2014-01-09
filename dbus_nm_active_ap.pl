#!/usr/bin/perl
use strict;
use warnings;
use Net::DBus;

# locally
$ENV{DISPLAY} = ':0.0';

my $rWlan = Net::DBus->session()
    ->get_service('org.freedesktop.NetworkManager.Device.Wireless')
    ->get_object('/org/freedesktop/NetworkManager/Device/Wireless', 'org.freedesktop.NetworkManager.Device.Wireless');
    
warn $rWlan->ActiveAccessPoint()->Ssid();

exit 0;

