#!perl -w
# -*-perl-*-

# Test that creating non-"user."-prefixed attributes fails.
# XXX: Probably Linux-specific

use strict;
use Test::More;
use POSIX qw/setlocale LC_ALL/;

BEGIN {
  my $tlib = $0;
  $tlib =~ s|/[^/]*$|/lib|;
  push(@INC, $tlib);
}
use t::Support;

if (t::Support::should_skip()) {
  plan skip_all => 'Tests unsupported on this OS/filesystem';
} else {
  plan tests => 8;
}

use File::Temp qw(tempfile);
use File::Path;
use File::ExtAttr qw(setfattr getfattr delfattr);

# Use the C locale, so all warnings are in the language we are expecting.
setlocale(LC_ALL, 'C');

# Snaffle away the warnings for later analysis.
my $warning;
$SIG{'__WARN__'} = sub { $warning = $_[0] };

my $TESTDIR = ($ENV{ATTR_TEST_DIR} || '.');
my ($fh, $filename) = tempfile( DIR => $TESTDIR );
close $fh || die "can't close $filename $!";

# Create a directory.
my $dirname = "$filename.dir";
eval { mkpath($dirname); };
if ($@) {
    warn "Couldn't create $dirname: $@";
}

#todo: try wierd characters in here?
#     try unicode?
my $key = "alskdfjadf2340zsdflksjdfa09eralsdkfjaldkjsldkfj";
my $val = "ZZZadlf03948alsdjfaslfjaoweir12l34kealfkjalskdfas90d8fajdlfkj./.,f";

foreach ( $filename, $dirname ) {
    print "# using $_\n";

    #set it
    setfattr($_, "$key", $val, { namespace => 'nonuser' });
    is ($warning =~ /(Operation not supported|No such file or directory|Attribute not found)/, 1);

    #read it back
    is (getfattr($_, "$key", { namespace => 'nonuser' }), undef);

    #delete it
    delfattr($_, "$key", { namespace => 'nonuser' });
    is ($warning =~ /(Operation not supported|No such file or directory|Attribute not found)/, 1);

    #check that it's gone
    is (getfattr($_, "$key", { namespace => 'nonuser' }), undef);
}

END {
    unlink $filename if $filename;
    rmdir $dirname if $dirname;
};
