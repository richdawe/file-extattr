package File::ExtAttr;

use 5.008005;
use strict;
use warnings;
use Carp;
use Scalar::Util;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use File::ExtAttr ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( getfattr setfattr delfattr
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.03';

#this is used by getxattr(), needs documentation
$File::ExtAttr::MAX_INITIAL_VALUELEN = 255;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&File::ExtAttr::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('File::ExtAttr', $VERSION);

# Preloaded methods go here.

sub _is_fh
{
    my $file = shift;
    my $is_fh = 0;

    eval
    {
        # TODO: Does this work with Perl 5.005, 5.6.x?
        # Relies on autovivification of filehandles?
        $is_fh = 1 if ($file->isa('IO::Handle'));

        # TODO: Does this work with Perl 5.005, 5.6.x?
        # Better solution for detecting a file handle?
        $is_fh = 1 if (openhandle($file));
    };

    return $is_fh;
}

sub getfattr
{
    my $file = shift;

    return _is_fh($file)
        # File handle
        ? _fgetfattr($file->fileno(), @_)
        # Filename
        : _getfattr($file, @_);
}

sub setfattr
{
    my $file = shift;

    return _is_fh($file)
        # File handle
        ? _fsetfattr($file->fileno(), @_)
        # Filename
        : _setfattr($file, @_);
}

sub delfattr
{
    my $file = shift;

    return _is_fh($file)
        # File handle
        ? _fdelfattr($file->fileno(), @_)
        # Filename
        : _delfattr($file, @_);
}

# TODO: l* functions

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

File::ExtAttr - Perl extension for blah blah blah

=head1 SYNOPSIS

  use File::ExtAttr;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for File::ExtAttr, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.

=head2 Exportable constants

  



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

The latest version of this software should be available from its
home page: L<http://sourceforge.net/projects/file-extattr/>

L<OS2::ExtAttr> provides access to extended attributes on OS/2.

Eiciel, L<http://rofi.pinchito.com/eiciel/>, is an access control list (ACL)
editor for GNOME; the ACLs are stored in extended attributes.

Various low-level APIs exist for manipulating extended attributes:

=over 4

=item Linux

L<http://www.die.net/doc/linux/man/man2/getxattr.2.html>

L<http://www.die.net/doc/linux/man/man5/attr.5.html>

=item OpenBSD

L<http://www.openbsd.org/cgi-bin/man.cgi?query=extattr_get_file&apropos=0&sektion=0&manpath=OpenBSD+Current&arch=i386&format=html>

=item FreeBSD

L<http://www.freebsd.org/cgi/man.cgi?query=extattr&sektion=2&apropos=0&manpath=FreeBSD+6.0-RELEASE+and+Ports>

=item NetBSD

L<http://netbsd.gw.com/cgi-bin/man-cgi?extattr_get_file+2+NetBSD-current>

=item Mac OS X

L<http://arstechnica.com/reviews/os/macosx-10.4.ars/7>

=item Solaris

L<http://docsun.cites.uiuc.edu/sun_docs/C/solaris_9/SUNWaman/hman3c/attropen.3c.html>

L<http://docsun.cites.uiuc.edu/sun_docs/C/solaris_9/SUNWaman/hman5/fsattr.5.html>

=back

=head1 AUTHOR

Kevin M. Goess, E<lt>kgoess@ensenda.comE<gt>

Richard Dawe, E<lt>rich@phekda.gotadsl.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kevin M. Goess

Copyright (C) 2005 by Richard Dawe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
