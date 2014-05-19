#!/usr/bin/env perl
use strict;
use warnings;

use Cwd;
use Data::Dumper;
use Getopt::Long;
use File::Basename;
#print Dumper(\@ARGV);

my $rhOptions = {};
my $bOptions = GetOptions
(
    'copy-files'            => \$rhOptions->{bCopyFiles},
    'local=s'               => \$rhOptions->{local},
    'base=s'                => \$rhOptions->{base},
    'remote=s'              => \$rhOptions->{remote},
    'merged=s'              => \$rhOptions->{merged},
    'branches=s'            => \$rhOptions->{branches},
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
    # FIXME hardcoded alternative .vimrc
    exec(sprintf('vim -u '.$ENV{HOME}.'/git/my_vim/.vimrc_ro -c %s', esa(make_script(`cat $sDiffFilesList`))));
}

sub copy_files
{
    system(sprintf('cp %s %s/', $rhOptions->{'local'}, $sTmpDir));
    open F, '>>'.$sDiffFilesList;
    print F $sTmpDir, '/', (fileparse($rhOptions->{'local'}))[0], "\t", getcwd(), '/', $rhOptions->{'remote'}, "\n";
    close F;
}

sub make_script
{
    my @files = @_;
    
    my $bNotFirst = 0;
    my $sScript = "set diffopt=filler,vertical\n";
    for my $sPair (@files)
    {
        $sScript .= "tabe\n" if $bNotFirst;
        $bNotFirst ||= 1;
        chomp($sPair);
        my @aPair = split /\t/, $sPair;
        $sScript .= "view $aPair[0]\n";
        $sScript .= "diffsplit $aPair[1]\n";
    }
    return $sScript;
}

sub esa
{
    my ($s) = @_;
    $s =~ s#'#'\\''#g;
    return "'$s'";
}

exit 0;
