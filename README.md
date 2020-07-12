NAME
====

Text::ShellWords - Split a string into words like a command-line shell

SYNOPSIS
========

```raku
use Text::ShellWords;

my $input = Q{printf "%s\n" 1 "2 hello" '3 world' 4\ .};
my @output = run(:out, shell-words $input).out.lines(:close);
.put for @output;       # OUTPUT: «1␤2 hello␤3 world␤4 .␤»
```

DESCRIPTION
===========

Text::ShellWords provides routines to split a string into words, respecting the Unix Bourne Shell (`/bin/sh`) quoting rules. From the `bash` manual page:

  * There are three quoting mechanisms: the escape character, single quotes, and double quotes.

    A non-quoted backslash (`\`) is the escape character. It preserves the literal value of the next character that follows, with the exception of *newline*. If a `\`*newline* pair appears, and the backslash is not itself quoted, the `\`*newline* is treated as a line continuation (that is, it is removed from the input stream and effectively ignored).

    Enclosing characters in single quotes preserves the literal value of each character within the quotes. A single quote may not occur between single quotes, even when preceded by a backslash.

    Enclosing characters in double quotes preserves the literal value of all characters within the quotes, with the exception of `\`. The backslash retains its special meaning only when followed by one of the following characters: `"`, `\`, or *newline*. A double quote may be quoted within double quotes by preceding it with a backslash.

  * Unlike the Bourne Shell, the characters `$`, `` ` ``, and `!` have no special meaning to this module.

class Text::ShellWords::Grammar
-------------------------------

Parsing grammar for a shell-input string

class Text::ShellWords::WordFailure
-----------------------------------

Error indicator for an incomplete parse

### Incomplete parsing

When the input string is malformed, or intended to continue on another line, the last word is made a `WordFailure` object, rather than a `Str`. This object behaves just like any `Failure`, but it stringifies to the final piece of input text if it has been `handled` (by testing if it is `True` or `defined`).

```raku
my @words = shell-words 'hello, "world';
put @words[0];      # OUTPUT «hello,␤»
try put @words[1];  # OUTPUT «»
put $!.message;     # OUTPUT «Input is malformed or incomplete, ends with '"world'␤»
# Now that it's been handled, it can used as a Str
put @words[1];      # OUTPUT «"world␤»
# But it is still a Failure
say @words[1].^name if not @words[1];   # OUTPUT: «Text::ShellWords::WordFailure␤»
```

class Text::ShellWords::Actions
-------------------------------

Actions class for C<.parse>. Use C<.new(:keep)> to keep quoting characters in the made words

shell-words
-----------

### sub shell-words

```perl6
sub shell-words(
    Cool:D $input,
    Bool :$keep = Bool::False
) returns Mu
```

Split a string into its shell-quoted words. If C<keep> is True, the quote characters are preserved in the returned words. By default they are removed.

SEE ALSO
========

This module is inspired by, but has different behavior than, Perl's [Text::ParseWords](https://metacpan.org/pod/Text::ParseWords) and [Text::Shellwords](https://metacpan.org/pod/Text::Shellwords).

The [Bash manual page](https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Quoting) describes the three quoting mechanisms copied by this module.

AUTHOR
======

Tim Siegel <siegeltr@gmail.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2020 Tim Siegel

This library is free software; you can redistribute and modify it under the [Artistic License 2.0](http://www.perlfoundation.org/artistic_license_2_0).

