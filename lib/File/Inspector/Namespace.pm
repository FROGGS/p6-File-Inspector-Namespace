
class File::Inspector::Namespace {
    my @_namespace;
    my $dont_do_anything = False;
    has $.code;
    has $!parsed = False;
    my $document_name;

    my $grammar = grammar {
        rule TOP          { <term>* }

        token identifier  { <.ident> [ <[\-']> <.ident> ]*   }
        token name        { <identifier> ['::'<identifier>]* }
        
        method panic ( *@args ) {
            
        }

        rule term ($parent = '') {
            [
            | <routine_declarator($parent)>
            | <package_declarator($parent)>
            | <attribute_declarator>
            | <package_import>
            | <pod_comment>
            | <variable>
            | <block($parent)>
            | <comment>
            | <unknown>
            ]
            ';'?
        }

        token variable {
            $<sigil>  = [ '$' || '%' || '@' ]
            $<twigil> = [ '.' || '!' || '?' || '=' || '*' ]?
            <identifier>
        }

        rule attribute_declarator {
            'has'
            $<sigil>  = [ '$' || '%' || '@' ]
            $<twigil> = [ '.' || '!' ]?
            <identifier>
        }

        rule signature {
            [ ':'? <variable> <[!?]>? ]* % [ ',' ]*
        }

        rule block ($parent = '') {
            '{'
            [
            ||  ['*' || '...' ] { @_namespace.=grep( none ($document_name ?? $document_name ~ '::' !! '') ~ $parent ) }
            ||  <term($parent)>*
            ] '}'
        }

        rule routine_declarator ($parent = '') {
            $<scope> = [ 'our' || 'my' || 'anon' ]?
            $<type>  = [ 'sub' || 'method' || 'token' || 'rule' ]
            <identifier>?
            [ '(' <signature> ')' ]?
            <block>
        }

        rule package_declarator ($parent = '') {
            :my $name;
            $<scope> = [ 'our' || $<private> = ['my' || 'anon'] ]?
            $<type>  = [ 'package' || 'module' || 'class' || 'role' || 'knowhow' || 'native' || 'slang' || 'grammar' || 'stub' ]
            <name>?
            {
                if ~$<name> && !~$<private> {
                    $name = ($parent ?? $parent ~ '::' !! '') ~ ~$<name>;
                    @_namespace.push: ($document_name ?? $document_name ~ '::' !! '') ~ $name;
                }
            }
            [ '[' <signature> ']' ]?
            [ <block($name)>
            ||  ';'
                {
                    $document_name = $name;
                    $dont_do_anything = True if ~$<private>;
                }
            ]
        }

        rule package_import {
            $<keyword>  = [ 'use' || 'need' || 'import' ]
            <name>
            $<end_keyword> = [ ';' || \h ]
        }

        proto token comment { <...> }

        token comment:sym<#> {
           '#' {} \N*
        }

        token comment:sym<#=> {
            '#=' \h+ $<attachment>=[\N*]
        }

        token pod_comment {
            ^^ \h* '='
            [
            | 'begin' \h+ 'END' >>
                [ .*? \n \h* '=' 'end' \h+ 'END' » \N* || .* ]
            | 'begin' \h+ <identifier>
                [
                ||  .*? \n \h* '=' 'end' \h+ $<identifier> » \N*
                ||  <.panic: '=begin without matching =end'>
                ]
            | 'begin' » \h*
                [ $$ || '#' || <.panic: 'Unrecognized token after =begin'> ]
                [
                || .*? \n \h* '=' 'end' » \N*
                || <.panic: '=begin without matching =end'>
                ]
            | <identifier>
                .*? ^^ <?before \h* [ 
                    '='
                    [ 'cut' »
                      <.panic: 'Obsolete pod format, please use =begin/=end instead'> ]?
                  | \n ]>
            |
                [ \s || <.panic: 'Illegal pod directive'> ]
                \N*
            ]
        }

        token unknown {
            .+? \n
        }
    }

    method namespace {
        self.parse unless $!parsed;
        if $dont_do_anything {
            return ();
        }
        @_namespace
    }

    method parse ( :$code? ) {
        $!parsed = True;
        if $code {
            $!code = $code;
            self.reset;
        }
        $grammar.parse( $!code );
    }
    
    method reset {
        @_namespace       = ();
        $document_name    = '';
        $dont_do_anything = False
    }
}
