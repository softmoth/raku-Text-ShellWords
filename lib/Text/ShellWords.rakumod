unit module Text::ShellWords:auth<github:softmoth>:api<1.0>:ver<0.1.0>;

=begin pod

=head1 NAME

Text::ShellWords - Split a string into words like a command-line shell

=head1 SYNOPSIS

=begin code :lang<raku>
use Text::ShellWords;

my $input = Q{printf "%s\n" 1 "2 hello" '3 world' 4\ .};
my @output = run(:out, shell-words $input).out.lines(:close);
.put for @output;       # OUTPUT: «1␤2 hello␤3 world␤4 .␤»
=end code

=head1 DESCRIPTION

Text::ShellWords provides routines to split a string into words, respecting
shell quoting rules.

Currently only the Unix Bourne Shell (`/bin/sh`) rules are implemented.

=end pod

our grammar Grammar {
    rule TOP {
        <?> <word> *
    }

    token word {
        <atom> +
    }

    proto regex atom { <...> }
    token atom:sym<backslashed> {
        \\ <( . )>
    }
    token atom:sym<single-str> {
        "'" ~ "'" (<-[']> *)
    }
    token atom:sym<double-str> {
        '"' ~ '"'
        [$<plain> = <-[\\"]> *] *
            %% $<bs> = [\\ .]
    }
    token atom:sym<simple> {
        # Because of Longest Token Matching, other atoms will always be
        # tried first. So we just need to avoid the word delimiter.
        \S
    }
}

our class Actions {
    has Bool $.keep;

    method TOP($/) { make $<word>.map(*.made) }
    method word($/) { make $<atom>».made.join }
    method atom:sym<backslashed>($/) { make ~$/ }
    method atom:sym<single-str>($/) {
        make ~ ($!keep ?? $/ !! $0);
    }
    method atom:sym<double-str>($/) {
        make $/.chunks.map(-> $c {
            given $c.key {
                when '~' { $!keep ?? $c.value !! '' }
                when 'bs' {
                    given $c.value.substr(1) {
                        when any(<\ ">)     { $_ }
                        # Escaped newline in double-quoted strings is
                        # removed entirely in Bourne Shell
                        when "\n"           { '' }
                        default             { $c.value }
                    }
                }
                when 'plain' { $c.value }
            }
        }).join
    }
    method atom:sym<simple>($/) { make ~$/ }
}

#| Split a string into its shell-quoted words
sub shell-words(
    Cool:D $input,
    Bool :$keep = False,

=for pod
If C<keep> is True, the quote characters are preserved in the returned words.
By default they are removed.

) is export {
    my $grammar = Grammar.new;
    my $actions = Actions.new: :$keep;

    $grammar.subparse($input, :$actions);
    $/ or die "Unexpected parse failure of ｢$input｣: $/";

    sub remainder($/) {
        if $/.pos < $/.orig.chars {
            Failure.new($/.orig.substr($/.pos))
                but role {
                    method Str { self.exception.message }
                }
        }
        else {
            Empty
        }
    }

    | $/.made, remainder($/)
}

=begin pod

=head1 AUTHOR

Tim Siegel <siegeltr@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Tim Siegel

This library is free software; you can redistribute and modify it under the
L<Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
=end pod
