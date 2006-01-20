package File::ExtAttr;

=head1 NAME

File::ExtAttr - Perl extension for accessing extended attributes of files

=head1 SYNOPSIS

  use File::ExtAttr ':all';
  use IO::File;
  
  # Manipulate the extended attributes of files.
  setfattr('foo.txt', 'user.colour', 'red') || die;
  my $colour = getfattr('bar.txt', 'user.colour');
  if (defined($colour))
  {
      print $colour;
      delfattr('bar.txt', 'user.colour');
  }
  
  # Manipulate the extended attributes of a file via a file handle.
  my $fh = new IO::File('<foo.txt') || die;
  setfattr($fh, 'user.colour', 'red') || die;
  
  $fh = new IO::File('<bar.txt') || die;
  $colour = getfattr($fh, 'user.colour');
  if (defined($colour))
  {
      print $colour;
      delfattr($fh, 'user.colour');
  }

=head1 DESCRIPTION

File::ExtAttr is a Perl module providing access to the extended attributes
of files.

Extended attributes are metadata associated with a file.
Examples are access control lists (ACLs) and other security parameters.
But users can add their own key=value pairs.

Extended attributes may not be supported by your operating system.
This module is aimed at Linux, Unix or Unix-like operating systems
(e.g.: Mac OS X, FreeBSD, NetBSD, OpenBSD).

Extended attributes may also not be supported by your filesystem
or require special options to be enabled for a particular filesystem
(e.g. "mount -o user_xattr /dev/hda1 /some/path").

NOTE: The API is not stable. It may change as part of supporting
multiple operating systems.

=cut

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

our $VERSION = '0.04';

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

=head1 METHODS

=over 4

=cut

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

=item getfattr([$filename | $filehandle], $attrname)

Return the value of the attribute named C<$attrname>
for the file named C<$filename> or referenced by the open filehandle
C<$filehandle> (which should be an IO::Handle).

If no attribute is found, returns C<undef>. Otherwise gives a warning.

=cut

sub getfattr
{
    my $file = shift;

    return _is_fh($file)
        # File handle
        ? _fgetfattr($file->fileno(), @_)
        # Filename
        : _getfattr($file, @_);
}

=item setfattr([$filename | $filehandle], $attrname, $attrval, [$flags])

Set the attribute named C<$attrname> with the value C<$attrval>
for the file named C<$filename> or referenced by the open filehandle
C<$filehandle> (which should be an IO::Handle).

C<$flags> allows control of whether the attribute should be created
or should replace an existing attribute's value. The value
C<File::ExtAttr::XATTR_CREATE> will cause setfattr to fail
if the attribute already exists. The value C<File::ExtAttr::XATTR_REPLACE>
will cause setfattr to fail if the attribute does not already exist.
If C<$flags> is omitted, then the attribute will be created if necessary
or silently replaced.

If the attribute could not be set, a warning is given.

=cut

sub setfattr
{
    my $file = shift;

    return _is_fh($file)
        # File handle
        ? _fsetfattr($file->fileno(), @_)
        # Filename
        : _setfattr($file, @_);
}

=item delfattr([$filename | $filehandle], $attrname)

Delete the attribute named C<$attrname> for the file named C<$filename>
or referenced by the open filehandle C<$filehandle>
(which should be an IO::Handle).

Returns true on success, otherwise false and a warning is given.

=cut

sub delfattr
{
    my $file = shift;

    return _is_fh($file)
        # File handle
        ? _fdelfattr($file->fileno(), @_)
        # Filename
        : _delfattr($file, @_);
}

=back

=cut

# TODO: l* functions

=head1 EXPORT

None by default.

You can request that C<getfattr>, C<setfattr> and C<delfattr> be exported
using the tag ":all".

=head2 Exportable constants

None

=head1 SEE ALSO

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

Copyright (C) 2005, 2006 by Richard Dawe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
__END__
