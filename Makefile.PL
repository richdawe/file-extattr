use lib qw(inc);
use ExtUtils::MakeMaker;
use Devel::CheckLib;
use strict;

# Check whether we have <attr/attributes.h> and <attr/xattr.h> on Linux.
# Suggest what the user needs to install, to get these files.

if ($^O eq 'linux') {
    check_lib_or_exit(
        lib => [qw(attr)]
    );
}

my @DIRS = qw(. /usr/include);
if ($^O eq 'linux')
{
    my %headers = (
        'attr/attributes.h' => 0,
        'attr/xattr.h' => 0,
    );
    my $incdir;
    my $missing = 0;

    foreach $incdir (@DIRS)
    {
        foreach (keys %headers)
        {
            $headers{$_}++ if (-r "$incdir/$_");
        }
    }

    foreach (keys %headers)
    {
        if ($headers{$_} == 0) {
            warn "<$_> not found; perhaps you need to install libattr-devel";
            $missing++;
        }
    }

    exit(0) if ($missing > 0);
}

# OpenBSD does not support extended attributes.
if ($^O eq 'openbsd') {
    warn 'OpenBSD does not support extended attributes';
    die "OS unsupported";
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'File::ExtAttr',
    VERSION_FROM      => 'lib/File/ExtAttr.pm', # finds $VERSION
    PREREQ_PM         => {
	# e.g., Module::Name => 1.1
	'Carp' => 0,
	'Scalar::Util' => 0
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/ExtAttr.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin M. Goess <kgoess@ensenda.com>'
                         .', Richard Dawe <richdawe@cpan.org>') : ()),
# Don't actually need -lattr on Linux.
#    LIBS              => ['-lattr'], # e.g., '-lm'
    OBJECT            => '$(O_FILES)',
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => join(' ', map { "-I$_" } @DIRS),
#    'MYEXTLIB' => 'mylib/libxattrlib$(LIB_EXT)',
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too

    # Hand-roll META.yml and MANIFEST.
    NO_META           => 1,
);
