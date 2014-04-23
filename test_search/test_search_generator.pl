#!/usr/bin/perl
use strict;
use MIME::Base64 qw/encode_base64/;
use Digest::MD5 qw/md5_hex/;
use IPC::Open2;

my $FILE = 'surfingbird.ru';
my $URLS_COUNT = 1000000;

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
    my $d = pack('N', length($u)).$u;
    print $f $d;
    printf $i "%s\t%d\n", md5_hex($u), $l;
    $l += length($d);
}
close $i;
my $j = 0;
my ($min, $max);
while (my $r = <$o>) {
    chomp($r);
    my ($h, $of) = split /\t/, $r;
    $h = pack('H*', $h);
    print $f $h, pack('Q', $of);
    $min = left_bytes_2_long($h) if !$j;
    $max = left_bytes_2_long($h) if eof;
    $j = 1;
}
print $f pack('Q', $l);
print $f pack('Q', $min);
print $f pack('Q', $max);
close $f;
close $o;


sub left_bytes_2_long {
    my ($s, $offset) = @_;
    $offset ||= 0;
    unpack('Q', join('', reverse(split //, substr($s, $offset, 8))));
};

