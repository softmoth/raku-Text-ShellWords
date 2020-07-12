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
the Unix Bourne Shell (`/bin/sh`) quoting rules. From the C<bash> manual
page:

=begin item
There are three quoting mechanisms: the escape character, single quotes, and
double quotes.

A non-quoted backslash (C<\>) is the escape character. It preserves the
literal value of the next character that follows, with the exception of
I<newline>. If a C<\>I<newline> pair appears, and the backslash is not
itself quoted, the C<\>I<newline> is treated as a line continuation (that
is, it is removed from the input stream and effectively ignored).

Enclosing characters in single quotes preserves the literal value of each
character within the quotes. A single quote may not occur between single
quotes, even when preceded by a backslash.

Enclosing characters in double quotes preserves the literal value of all
characters within the quotes, with the exception of C<\>. The backslash
retains its special meaning only when followed by one of the following
characters: C<">, C<\>, or I<newline>. A double quote may be quoted within
double quotes by preceding it with a backslash.
=end item

=for item
Unlike the Bourne Shell, the characters C<$>, C<`>, and C<!> have no special
meaning to this module.

=end pod

my class X::Text::ShellWords::Incomplete is Exception {
    has $.word;
    method message { "Input is malformed or incomplete, ends with '$!word'" }
}

module Text::ShellWords:auth<github:softmoth>:api<1.0>:ver<0.1.0> {
    #| Parsing grammar for a shell-input string
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
        token atom:sym<incomplete> {
            # Catch atom prefixes to identify an incomplete atom at the end
            \\ | "'" | '"'
        }
        token atom:sym<simple> {
            # Because of Longest Token Matching, other atoms will always be
            # tried first, so we just need to avoid the word delimiter
            \S
        }
    }

    #| Error indicator for an incomplete parse
    my class WordFailure is Failure {

=head3 Incomplete parsing

=for pod
When the input string is malformed, or intended to continue on another line,
the last word is made a C<WordFailure> object, rather than a C<Str>. This
object behaves just like any C<Failure>, but it stringifies to the final
piece of input text if it has been C<handled> (by testing if it is C<True>
or C<defined>).

=begin code :lang<raku>
my @words = shell-words 'hello, "world';
put @words[0];      # OUTPUT «hello,␤»
try put @words[1];  # OUTPUT «»
put $!.message;     # OUTPUT «Input is malformed or incomplete, ends with '"world'␤»
# Now that it's been handled, it can used as a Str
put @words[1];      # OUTPUT «"world␤»
# But it is still a Failure
say @words[1].^name if not @words[1];   # OUTPUT: «Text::ShellWords::WordFailure␤»
=end code

        method Str {
            self.handled ?? self.exception.word !! self.fail
        }
    }

    #| Actions class for C<.parse>. Use C<.new(:keep)> to keep quoting
    #| characters in the made words
    our class Actions {
        has Bool $.keep;

        method TOP($/) { make $<word>.map(*.made) }
        method word($/) {
            my $incomplete;
            my $word = '';
            for $<atom>».made {
                when Pair { $incomplete = True; $word ~= .value }
                default   { $word ~= $_ }
            }

            make $incomplete
                    ?? WordFailure.new(X::Text::ShellWords::Incomplete.new: :$word)
                    !! $word;
        }
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
        method atom:sym<incomplete>($/) { make 'incomplete' => ~$/ }
        method atom:sym<simple>($/) { make ~$/ }
    }


=head2 shell-words

    #| Split a string into its shell-quoted words. If C<keep> is True, the
    #| quote characters are preserved in the returned words. By default they
    #| are removed.
    sub shell-words(
        Cool:D $input,
        Bool :$keep = False,
    ) is export {
        my $grammar = Grammar.new;
        my $actions = Actions.new: :$keep;

        $grammar.parse($input, :$actions)
            or die "Unexpected parse failure of ｢$input｣";

        $/.made<>
    }
}

=begin pod

=head1 SEE ALSO

This module is inspired by, but has different behavior than, Perl's
L<Text::ParseWords|https://metacpan.org/pod/Text::ParseWords> and
L<Text::Shellwords|https://metacpan.org/pod/Text::Shellwords>.

The L<Bash manual page|https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Quoting> describes the three quoting mechanisms copied by this module.

=head1 AUTHOR

Tim Siegel <siegeltr@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Tim Siegel

This library is free software; you can redistribute and modify it under the
L<Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
=end pod
