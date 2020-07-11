use Test;
use Text::ShellWords;

plan 4;

sub run-tests(*@tests) {
    plan +@tests;
    is-deeply shell-words(.key), .value, "｢{.key}｣" for @tests;
}

subtest "bare words" => sub {
    run-tests
        Q{} => (),
        Q{ } => (),
        Q{one} => ('one',),
        Q{one two} => <one two>,
        Q{one two three} => <one two three>,
        Q{ one  two   three } => <one two three>,
        ;
}

subtest "backslash escape" => sub {
    run-tests
        Q{one\ two} => (Q{one two},),
        Q{one\ntwo} => (Q{onentwo},),
        Q{one\"two} => (Q{one"two},),
        Q{one\'two} => (Q{one'two},),
        Q{one\\two} => (Q{one\two},),
        ;
}

subtest "single quotes" => sub {
    run-tests
        Q{'hello world'} => ('hello world',),
        Q{one 'two and' three} => ('one', 'two and', 'three'),
        Q{'a\\b'} => (Q{a\\b},),
        Q{a X'hello world' b\'} => ('a', 'Xhello world', "b'"),
        ;
}

subtest "double quotes" => sub {
    run-tests
        Q{"hello world"} => ('hello world',),
        Q{one "two and" three} => ('one', 'two and', 'three'),
        Q{"a\\b"} => (Q{a\b},),
        Q{"a\"b"} => (Q{a"b},),
        Q{"a\nb"} => (Q{a\nb},),
        Q{a X"hello world" b\"} => ('a', 'Xhello world', 'b"'),
        ;
}

# vi:ft=raku
