p6-File-Inspector-Namespace
===========================

This module is intended to provide a way to get the GLOBAL symbols a piece of code would export.

Usage:

  use File::Inspector::Namespace;
  my $parser = File::Inspector::Namespace.new( code => 'module A; class B { class C { } }' );
  say $parser.namespace;

  OUTPUT (.perl): ("A", "A::B", "A::B::C")
  
  $parser.parse( code => slurp 'some/interesting/file.pm' )
  say $parser.namespace;

The method .namespace will give you an array of symbols, depending on the order in wich they appear in the code.
Recognizable symbols are declarations of:
  - package
  - module
  - class
  - role
  - knowhow
  - native
  - slang
  - grammar

If a symbol is declared as 'my' or 'anon' or is a stub, it will ne ignored.
If the whole file is in a my/anon scoped declaration, no symbols will be returned by the .namespace method.
