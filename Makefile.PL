use lib qw(inc);
use ExtUtils::MakeMaker;
use Devel::CheckLib;
use Cwd;
use File::Temp qw/tempdir/;
use IO::File;
use strict;

# Check whether we have an "xattr.h" on Linux.
# Suggest what the user needs to install, to get these files.

my (@DEFINES, @LIBS);

if ($^O eq 'linux') {
    # check for libc6-dev first
    if (!check_lib( header => [qw(sys/xattr.h)] ) ) {
        warn "'sys/xattr.h' not found. Either package 'lib6-dev' is not installed, or is very old\n";
        warn "Trying for 'attr/xattr.h' from package 'libattr1-dev'\n";
        check_lib_or_exit(
            header => [qw(sys/types.h attr/xattr.h attr/attributes.h )],
            lib    => [qw(attr)],
        );
        push @DEFINES, 'HAS_LIBATTR';
        # Don't actually need -lattr on Linux - is this only if the libc supports xattrs?
        push @LIBS, 'attr';
    }
}

# OpenBSD does not support extended attributes.
if ($^O eq 'openbsd') {
    warn 'OpenBSD does not support extended attributes';
    die "OS unsupported";
}

# Check whether extended attributes are supported on this filesystem.
# If we're running non-interactive there is no point failing all the tests,
# because the machine is not set up correctly.
if ($^O eq 'linux') {
    my $basedir = $ENV{ATTR_TEST_DIR} || getcwd();
    my $template .= "$basedir/XXXXXXXX";
    my $dir = tempdir($template, CLEANUP => 1);
    my $file = "$dir/testfile";
    my $fh = new IO::File(">$file") or die "Unable to open $file: $!";
    undef $fh;

    my $output = `setfattr -n user.foo -v foo $file 2>&1`;
    if ($output =~ /command not found/i) {
        warn "Please install the attr package (containing the setfattr program)";
        exit(0) if ($ENV{AUTOMATED_TESTING});
    }
    if ($output =~ /Operation not supported/i) {
        warn "To run the tests, you need mount the filesystem containing $basedir with the user_xattr option";
        warn "Alternatively set the environment variable ATTR_TEST_DIR to point at a filesystem where user_xattr is enabled";
        exit(0) if ($ENV{AUTOMATED_TESTING});
    }
}

# TODO: Check filesystem on other operating systems

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
    LIBS              => join(' ', map { "-l$_" } @LIBS),
    OBJECT            => '$(O_FILES)',
    DEFINE            => join(' ', map { "-D$_" } @DEFINES),
   # INC               => join(' ', map { "-I$_" } @DIRS),
#    'MYEXTLIB' => 'mylib/libxattrlib$(LIB_EXT)',
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too

    # Hand-roll META.yml and MANIFEST.
    NO_META           => 1,
);
