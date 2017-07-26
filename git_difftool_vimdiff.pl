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
    'no-pull'               => \$rhOptions->{bNoPull},
    'with-local'            => \$rhOptions->{bWithLocal},
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
        unless ($rhOptions->{bNoPull})
        {
            system(sprintf('git checkout %s && git pull origin %s', ($_) x 2)) && die for split /\.\./, $rhOptions->{branches};
        }
        system(sprintf('touch %s/with_local', $sTmpDir)) if $rhOptions->{bWithLocal};
        system(sprintf('git difftool %s --no-prompt --tool gdv %s', $rhOptions->{branches}, join(' ', @ARGV)));
    }
    else
    {
        my $cmd = sprintf('git difftool --no-prompt --tool gdv %s', join(' ', @ARGV));
        system($cmd);
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
        if (-f $sTmpDir.'/with_local')
        {
            $sRemote = getcwd() . '/' . $sRemote;
        }
        else
        {
            $sRemote =~ s!/!_!g;
            $sRemote = $sTmpDir . '/' . $sRemote;
            system(sprintf('cp %s %s', $rhOptions->{remote}, $sRemote));
        }
        system(sprintf('cp %s %s/', $rhOptions->{'local'}, $sTmpDir));
        open F, '>>'.$sDiffFilesList;
        print F $sTmpDir, '/', (fileparse($rhOptions->{'local'}))[0], "\t", $sRemote, "\n";
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
        chomp($sPair);
        $sScript .= "tabe\n" if $bNotFirst;
        $bNotFirst ||= 1;
        my @aPair = split /\t/, $sPair;
        if ($rhOptions->{branches} && !$rhOptions->{bWithLocal})
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
