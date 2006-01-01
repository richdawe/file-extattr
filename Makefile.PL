use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'File::ExtAttr',
    VERSION_FROM      => 'lib/File/ExtAttr.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/ExtAttr.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin M. Goess <kgoess@ensenda.com>'
                         .', Richard Dawe <rich@phekda.gotadsl.co.uk>') : ()),
# Don't actually need -lattr on Linux.
#    LIBS              => ['-lattr'], # e.g., '-lm'
    OBJECT            => '$(O_FILES)',
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -I/usr/include', # e.g., '-I. -I/usr/include/other'
#    'MYEXTLIB' => 'mylib/libxattrlib$(LIB_EXT)',
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(XATTR_CREATE XATTR_REPLACE));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'File::ExtAttr',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}


 sub MY::postamble {
'
$(MYEXTLIB): mylib/Makefile
		cd mylib && $(MAKE) $(PASSTHRU)
';
}
