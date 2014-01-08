#!/usr/bin/perl
use strict;
use Net::Telnet;

while (1)
{
    our $iSleep ||= 10;
    sleep $iSleep;
    my $iPid = client_pid();
    my $bServer = check_server();
    if ($iPid && $bServer)
    {
        $iSleep = 600;
        warn localtime().' ($iPid && $bServer) sleep: '.$iSleep."; pid: $iPid\n";
    }
    elsif (!$iPid && !$bServer)
    {
        $iSleep = 10;
        warn localtime().' (!$iPid && !$bServer) sleep: '.$iSleep."; pid: $iPid\n";
    }
    elsif ($iPid && !$bServer)
    {
        kill 15, $iPid;
        $iSleep = 10;
        warn localtime().' ($iPid && !$bServer) sleep: '.$iSleep."; pid: $iPid (killed)\n";
    }
    elsif (!$iPid && $bServer)
    {
        system('synergyc -d FATAL -l /dev/null --no-tray --name debwork localhost:24800');
        $iSleep = 600;
        warn localtime().' (!$iPid && $bServer) sleep: '.$iSleep."; pid: ".client_pid()." (started)\n";
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
        $t ||= Net::Telnet->new(Port=>24800);
        eval
        {
            $t->open();
            $t->waitfor('/Synergy/');
            $t->close();
        };
        return $@ ? 0 : 1;
    }
}

