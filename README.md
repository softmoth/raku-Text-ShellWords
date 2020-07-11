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

Text::ShellWords provides routines to split a string into words, respecting shell quoting rules.

Currently only the Unix Bourne Shell (`/bin/sh`) rules are implemented.

### sub shell-words

```perl6
sub shell-words(
    Cool:D $input,
    Bool :$keep = Bool::False
) returns Mu
```

Split a string into its shell-quoted words

If `keep` is True, the quote characters are preserved in the returned words. By default they are removed.

AUTHOR
======

Tim Siegel <siegeltr@gmail.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2020 Tim Siegel

This library is free software; you can redistribute and modify it under the [Artistic License 2.0](http://www.perlfoundation.org/artistic_license_2_0).

