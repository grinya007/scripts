#!/usr/bin/perl
use strict;
use MIME::Base64 qw/encode_base64/;
use Digest::MD5 qw/md5_hex/;
use IPC::Open2;

my $FILE = 'surfingbird.com';
my $URLS_COUNT = 100;

my $l = 0;
my ($i, $o, $f);
open2($o, $i, 'LC_COLLATE=C sort -S 500M');
open($f, ">$FILE");

my $params_counts = [0, 0, 0, 0, 1, 1, 1, 2, 2, 3, 3, 4];
for (1..$URLS_COUNT) {
    my $s = encode_base64(pack("N", int(rand(4000000000)))); 
    chomp($s); 
    $s =~ s/[=+\/]//g; 
    my $t = join("&", ("param=".int(rand(1000000))) x $params_counts->[int(rand(12))]);
    my $u = sprintf("http://$FILE/surf/%s%s", $s, ($t ? "?$t" : "")); 
    print $f $u;
    printf $i "%s\t%d\n", md5_hex($u), $l;
    $l += length($u);
}
close $i;
my $i = 0;
my ($min, $max);
while (my $r = <$o>) {
    chomp($r);
    my ($h, $of) = split /\t/, $r;
    #warn $h;
    print $f pack('H*', $h), pack('Q', $of);
}
print $f pack('Q', $l);
close $f;
close $o;
