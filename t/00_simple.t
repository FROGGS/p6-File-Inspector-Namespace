
use Test;
use lib 'lib';
use File::Inspector::Namespace;

plan 13;

# like can_ok
for <parse namespace reset> -> $method {
	ok File::Inspector::Namespace.^methods.first( $method ), "we can call File::Inspector::Namespace.$method"
}

# 'real' tests of the parser
my %table = (
    'class A;'                                                        => <A>,
    'class A; sub a { class B { } };'                                 => <A A::B>,
    'class A { class B { } }'                                         => <A A::B>,
    'sub a { class B { } };'                                          => <B>,
    'sub a { class B { } }; class A;'                                 => <B A>, # in real life: Too late for semicolon form of class definition
    'sub a { class B { } }; class A {};'                              => <B A>,
    'class A { }; sub a { class B { } };'                             => <A B>,
    'my class A; sub a { class B { } };'                              => '',
    'class A { class B { }; class C { } }'                            => <A A::B A::C>,
    'module A; class B { class C { }; class D { ... } }; class E { }' => <A A::B A::B::C A::E>,
);

my $parser = File::Inspector::Namespace.new;

for %table.kv -> $code, $expected {
    $parser.parse( :$code );
    is $parser.namespace, $expected, "'$code' is <$expected>";
}
