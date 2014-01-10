#!/usr/bin/perl
use strict;
use Net::Telnet;

while (1)
{
    sleep 5;
    my $iPid = client_pid();
    my $bServer = check_server();
    my $bLock = 0;
    if ($iPid && $bServer)
    {
        warn localtime().' ($iPid && $bServer) sleep: '.$iSleep."; pid: $iPid\n";
    }
    elsif (!$iPid && !$bServer)
    {
        $bLock = 1;
        warn localtime().' (!$iPid && !$bServer) sleep: '.$iSleep."; pid: $iPid\n";
    }
    elsif ($iPid && !$bServer)
    {
        $bLock = 1;
        kill 15, $iPid;
        warn localtime().' ($iPid && !$bServer) sleep: '.$iSleep."; pid: $iPid (killed)\n";
    }
    elsif (!$iPid && $bServer)
    {
        system('synergyc -d FATAL -l /dev/null --no-tray --name debwork localhost:24800');
        warn localtime().' (!$iPid && $bServer) sleep: '.$iSleep."; pid: ".client_pid()." (started)\n";
    }
    if ($bLock)
    {
        system('/home/ag/.scripts/dbus_gnome_lock.pl --lock');
    }
}

sub client_pid
{
    my ($iPid) = `pgrep synergyc`;
    chomp $iPid if $iPid;
    return $iPid ? $iPid : 0;
}

{
    my $t;
    sub check_server
    {
        $t ||= Net::Telnet->new(Port=>24800,Timeout=>10);
        eval
        {
            $t->open();
            $t->waitfor('/Synergy/');
            $t->close();
        };
        return $@ ? 0 : 1;
    }
}

