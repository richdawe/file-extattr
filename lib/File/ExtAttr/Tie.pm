package File::ExtAttr::Tie;

=head1 NAME

File::ExtAttr::Tie - Tie interface to extended attributes of files

=head1 SYNOPSIS

  use File::ExtAttr::Tie;
  use Data::Dumper;

  tie %a, "File::ExtAttr::Tie", "/Applications (Mac  OS 9)/Sherlock 2";
  print Dumper \%a;

produces:

  $VAR1 = {
           'com.apple.FinderInfo' => 'APPLfndf!?',
           'com.apple.ResourceFork' => '?p?p5I'
          };

=head1 DESCRIPTION

File::ExtAttr::Tie provides access to extended attributes of a file
through a tied hash. Creating a new key creates a new extended attribute
associated with the file. Modifying the value or removing a key likewise
modifies/removes the extended attribute.

Internally this module uses the File::ExtAttr module. So it has
the same restrictions as that module in terms of OS support.

=cut

use strict;
use base qw(Tie::Hash);
use File::ExtAttr qw(:all);

our $VERSION = '0.01';

sub TIEHASH {
  my($class, $file) = @_;
  return bless { file => $file }, ref $class || $class;
}

sub STORE {
  my($self, $name, $value) = @_;
  return undef unless setfattr($self->{file}, $name, $value);
  $value;
}

sub FETCH {
  my($self, $name) = @_;
  return getfattr($self->{file}, $name);
}

sub FIRSTKEY {
  my($self) = @_;
  $self->{each_list} = [listfattr($self->{file})];
  shift @{$self->{each_list}};
}

sub NEXTKEY {
  my($self) = @_;
  shift @{$self->{each_list}};
}

sub EXISTS {
  my($self, $name) = @_;
  return getfattr($self->{file}, $name) ne undef;
}

sub DELETE {
  my($self, $name) = @_;
  my $value = getfattr($self->{file}, $name);
  return $value if delfattr($self->{file}, $name);
  undef;
}

sub CLEAR {
  my($self) = @_;
  for(listfattr($self->{file})) {
    delfattr($self->{file}, $_);
  }
}

#sub SCALAR { }

=head1 SEE ALSO

L<File::ExtAttr>

=head1 AUTHOR

David Leadbeater, L<http://dgl.cx/contact>

Documentation by Richard Dawe, E<lt>rich@phekda.gotadsl.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by David Leadbeater

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

1;
__END__
