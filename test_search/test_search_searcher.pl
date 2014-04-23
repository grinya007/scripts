#!/usr/bin/perl
use strict;
use Digest::MD5 qw/md5/;

my $FILE = $ARGV[0];
my $FIND = $ARGV[1];
my $INDEX_ROW_LENGTH = 16 + 8; # md5 hash + 64-bit int offset
my $ROWS_TO_SCAN = 10000;
my $MAX_LONG_VALUE = 0xffffffffffffffff;
#warn sprintf("%16x", $MAX_LONG_VALUE);

die 'wha?' if (!$FILE || !-f($FILE) || !$FIND);

my $file_size = -s($FILE);
open F, $FILE;
my $data_length;
warn 'doing first seek to read data length';
sysseek(F, -8, 2); # SEEK_END
sysread(F, $data_length, 8);
$data_length = unpack('Q', $data_length);
warn 'we got '.$data_length.' bytes of data';
my $rows_count = ($file_size - 8 - $data_length) / $INDEX_ROW_LENGTH;
warn 'we got '.$rows_count.' rows of data';

my $find_hash = md5($FIND);
my $find_prefix = unpack('Q', join('', (split //, $find_hash)[0..7]));
warn 'searching for '.$find_prefix;

my $guess_position = sprintf("%.0f", ($find_prefix * $rows_count) / $MAX_LONG_VALUE) + 0;
warn 'your row is nearby '.$guess_position.' position';

my $scan_start = $guess_position <= $ROWS_TO_SCAN/2 ? 0 : $guess_position - $ROWS_TO_SCAN/2;
my $scan_offset = $rows_count > $scan_start + $ROWS_TO_SCAN ? $ROWS_TO_SCAN : $rows_count - $scan_start;
warn 'doing second seek to try rows range';
sysseek(F, $data_length + $scan_start * $INDEX_ROW_LENGTH, 0);

my $b;
sysread(F, $b, $scan_offset * $INDEX_ROW_LENGTH);

my $i = 0;
my @a = split //, $b;
#warn @a[0..20];
while (@a) {
    #warn scalar(@a);
    my @tmp = splice(@a, 0, 24);
    die 'wtf' if scalar(@tmp) != 24;
    #my $prefix = unpack('C', join('', $tmp[0]));
    my $prefix = (ord($tmp[0])<<56)+(ord($tmp[1])<<48)+(ord($tmp[2])<<40)+(ord($tmp[3])<<32)+(ord($tmp[4])<<24)+(ord($tmp[5])<<16)+(ord($tmp[6])<<8)+(ord($tmp[7]));
    #warn $find_prefix;
    #warn $prefix;
    die 'you miss right' if !$i && $prefix >= $find_prefix;
    die 'you got it on '.$i.' step' if $i && $prefix >= $find_prefix;
    die 'you miss left' if !scalar(@a) && $prefix <= $find_prefix;
    $i++;
}

