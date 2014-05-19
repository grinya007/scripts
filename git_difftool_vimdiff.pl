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
    if ($rhOptions->{branches}) 
    {
        system(sprintf('git checkout %s && git pull origin %s', ($_) x 2)) && die for split /\.\./, $rhOptions->{branches};
        system(sprintf('git difftool %s --tool gdv %s', $rhOptions->{branches}, join(' ', @ARGV)));
    }
    else
    {
        system(sprintf('git difftool --tool gdv %s', join(' ', @ARGV)));
    }
    return if !-f $sDiffFilesList;
    # FIXME hardcoded alternative .vimrc
    exec(sprintf('vim -u '.$ENV{HOME}.'/git/my_vim/.vimrc_ro -c %s', esa(make_script(`cat $sDiffFilesList`))));
}

sub copy_files
{
    #warn Dumper $rhOptions;
    #return;
    if ($rhOptions->{remote} =~ m!^/tmp!) # FIXME FIXME branches mode
    {
        my $sRemote = $rhOptions->{base};
        $sRemote =~ s!/!_!g;
        system(sprintf('cp %s %s/', $rhOptions->{'local'}, $sTmpDir));
        system(sprintf('cp %s %s/%s', $rhOptions->{remote}, $sTmpDir, $sRemote));
        open F, '>>'.$sDiffFilesList;
        print F $sTmpDir, '/', (fileparse($rhOptions->{'local'}))[0], "\t", $sTmpDir, '/', $sRemote, "\n";
        close F;
    }
    else
    {
        system(sprintf('cp %s %s/', $rhOptions->{'local'}, $sTmpDir));
        open F, '>>'.$sDiffFilesList;
        print F $sTmpDir, '/', (fileparse($rhOptions->{'local'}))[0], "\t", getcwd(), '/', $rhOptions->{'remote'}, "\n";
        close F;
    }
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
        if ($rhOptions->{branches}) 
        {
            $sScript .= "view $aPair[0]\ndiffthis\nvsplit\n";
            $sScript .= "view $aPair[1]\ndiffthis\n";
        }
        else
        {
            $sScript .= "view $aPair[0]\n";
            $sScript .= "diffsplit $aPair[1]\n";
        }
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
