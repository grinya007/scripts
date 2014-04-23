#!/usr/bin/perl
use strict;
use Digest::MD5 qw/md5/;

my $FILE = $ARGV[0];
my $FIND = $ARGV[1];
my $INDEX_ROW_LENGTH = 16 + 8; # md5 hash + 64-bit int offset
my $ROWS_TO_SCAN = 20000;

die 'wha?' if (!$FILE || !-f($FILE) || !$FIND);

my $file_size = -s($FILE);
open F, $FILE;
my $meta_data;
warn 'doing first seek to read data length';
sysseek(F, -24, 2); # SEEK_END
sysread(F, $meta_data, 24);
my $data_length = unpack('Q', substr($meta_data, 0, 8));
my $min_prefix = unpack('Q', substr($meta_data, 8, 8));
my $max_prefix = unpack('Q', substr($meta_data, 16, 8));
warn 'we got '.$data_length.' bytes of data';
my $rows_count = ($file_size - 24 - $data_length) / $INDEX_ROW_LENGTH;
warn 'we got '.$rows_count.' rows of data';

my $find_hash = md5($FIND);
my $find_prefix = left_bytes_2_long($find_hash);

my $guess_position = int(($find_prefix * $rows_count) / ($max_prefix - $min_prefix));
warn 'your row is nearby '.$guess_position.' position';

my $scan_start = $guess_position <= $ROWS_TO_SCAN/2 ? 0 : $guess_position - $ROWS_TO_SCAN/2;
my $scan_offset = $rows_count > $scan_start + $ROWS_TO_SCAN ? $ROWS_TO_SCAN : $rows_count - $scan_start;
warn 'doing second seek to try rows range';
sysseek(F, $data_length + $scan_start * $INDEX_ROW_LENGTH, 0);

my $b;
my $scan_length = $scan_offset * $INDEX_ROW_LENGTH;
sysread(F, $b, $scan_length);
die 'mazafaka happened' if $scan_length != length($b);

my $first_row = substr($b, 0, $INDEX_ROW_LENGTH);
my $last_row = substr($b, ($scan_offset - 1) * $INDEX_ROW_LENGTH, $INDEX_ROW_LENGTH);

my ($first_prefix, $last_prefix) = map { left_bytes_2_long($_) } ($first_row, $last_row);

warn 'is      '.$find_prefix."\n";
warn 'between '.$first_prefix."\n";
warn 'and     '.$last_prefix.' huh?'."\n";

warn $find_prefix > $first_prefix ? 'left ok' : 'left bad';
warn $find_prefix < $last_prefix ? 'right ok' : 'rigth bad';


sub left_bytes_2_long {
    my ($s, $offset) = @_;
    $offset ||= 0;
    unpack('Q', join('', reverse(split //, substr($s, $offset, 8))));
};

