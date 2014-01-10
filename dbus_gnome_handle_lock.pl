#!/usr/bin/perl
use strict;
use warnings;
use Net::DBus;
use Net::DBus::Reactor;

# locally
$ENV{DISPLAY} = ':0.0';

my $WLAN_IFACE = 'wlan0';
my $WORKPLACE_AP = '84:78:AC:8C:A4:10';
my $LOCK_COMMAND = 'ssh work -q /home/ag/.scripts/dbus_gnome_lock.pl --lock';
my $UNLOCK_COMMAND = 'ssh work -q /home/ag/.scripts/dbus_gnome_lock.pl --unlock';
my $CHECK_NETWORK_COMMAND = 'nohup ssh home >/dev/null';
my $CHECK_TUNNEL_COMMAND = 'nohup ssh work >/dev/null';
my $SET_TUNNEL_COMMAND = 'nohup ssh work_tunnel /home/ag/.scripts/idle.sh >/dev/null &';

my $rScreenSaver = Net::DBus->session()
    ->get_service('org.gnome.ScreenSaver')
    ->get_object('/org/gnome/ScreenSaver', 'org.gnome.ScreenSaver');
my $rNM = Net::DBus->system()
    ->get_service('org.freedesktop.NetworkManager');
my $sWlan0 = $rNM
    ->get_object('/org/freedesktop/NetworkManager', 'org.freedesktop.NetworkManager')
    ->GetDeviceByIpIface($WLAN_IFACE);
my $rWlan0 = $rNM
    ->get_object($sWlan0, 'org.freedesktop.NetworkManager.Device.Wireless');

$rScreenSaver->connect_to_signal
(
    'ActiveChanged',
    sub
    {
        my ($bLocked) = @_;
        my $sBSSID;
        eval
        {
            my $rAP = $rNM
                ->get_object($rWlan0->ActiveAccessPoint(), 'org.freedesktop.NetworkManager.AccessPoint');
            $sBSSID = $rAP->HwAddress();
        };
        if ($sBSSID)
        {
            if ($sBSSID eq $WORKPLACE_AP)
            {
                set_work_locked($bLocked);
            }
            else
            {
                set_work_locked(1); # just in case
            }
        }
    }
);

$rWlan0->connect_to_signal
(
    'PropertiesChanged',
    sub
    {
        my ($rhProp) = @_;
        if (defined($rhProp->{ActiveAccessPoint}))
        {
            my $sBSSID;
            eval
            {
                my $rAP = $rNM
                    ->get_object($rhProp->{ActiveAccessPoint}, 'org.freedesktop.NetworkManager.AccessPoint');
                $sBSSID = $rAP->HwAddress();
            };
            if ($sBSSID)
            {
                if ($sBSSID eq $WORKPLACE_AP)
                { # oh my god
                    my $bNetworkOk = 0;
                    for (0..9)
                    {
                        if (!$_ && !set_work_locked($rScreenSaver->GetActive()))
                        {
                            last;
                        }
                        if (system($CHECK_NETWORK_COMMAND))
                        {
                            sleep 2;
                        }
                        else
                        {
                            $bNetworkOk = 1;
                            last;
                        }
                    }
                    if ($bNetworkOk)
                    {
                        my $bTunnelOk = 0;
                        for (0..11)
                        {
                            if (system($CHECK_TUNNEL_COMMAND))
                            {
                                system($SET_TUNNEL_COMMAND) unless $_;
                                sleep 5;
                            }
                            else
                            {
                                $bTunnelOk = 1;
                                last;
                            }
                        }
                        if ($bTunnelOk)
                        {
                            set_work_locked($rScreenSaver->GetActive());
                        }
                    }
                }
                else
                {
                    set_work_locked(1); # just in case
                }
            }
        }
    }
);

Net::DBus::Reactor->main()->run();

sub set_work_locked
{
    my ($bLock) = @_;
    return system($bLock ? $LOCK_COMMAND : $UNLOCK_COMMAND);
}

exit 0;

