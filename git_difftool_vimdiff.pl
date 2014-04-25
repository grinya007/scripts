#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
#print Dumper(\@ARGV);

my $rhOptions = {};
my $bOptions = GetOptions
(
    'copy-files'            => \$rhOptions->{bCopyFiles},
    'local=s'               => \$rhOptions->{local},
    'base=s'                => \$rhOptions->{base},
    'remote=s'              => \$rhOptions->{remote},
    'merged=s'              => \$rhOptions->{merged},
);
die if !$bOptions;

my $sTmpDir = sprintf('%s/local/tmp/git', $ENV{HOME});
my $sDiffFilesList = sprintf('%s/diff_files', $sTmpDir);

if ($rhOptions->{bCopyFiles})
{
    copy_files();
}
else
{
    run_difftool();
}

sub run_difftool
{
    system(sprintf('mkdir -p %s', $sTmpDir));
    system(sprintf('rm %s/*', $sTmpDir));
    system(sprintf('git difftool --tool gdv %s', join(' ', @ARGV)));
    return if !-f $sDiffFilesList;
    exec(sprintf('vim -c %s', esa(make_script(`cat $sDiffFilesList`))));
}

sub copy_files
{
    print Dumper($rhOptions);
}

sub make_script
{
    my @files = @_;
    
}

sub esa
{
    my ($s) = @_;
    $s =~ s#'#'\\''#g;
    return "'$s'";
}

exit 0;
