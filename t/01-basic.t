use Test;
use Text::ShellWords;

plan 6;

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

subtest "multi-line input" => sub {
    run-tests
        Q:to/END/
                hello
                world
                END
            => ('hello', 'world',),
        Q:to/END/
                hello\
                world
                END
            => ('helloworld',),
        Q:to/END/
                'hello
                world'
                END
            => ("hello\nworld",),
        Q:to/END/
                'hello\
                world'
                END
            => ("hello\\\nworld",),
        Q:to/END/
                "hello
                world"
                END
            => ("hello\nworld",),
        Q:to/END/
                "hello\
                world"
                END
            => ("helloworld",),
        Q:to/END/
                "hello \
                 world"
                END
            => ("hello  world",),
        ;
}

subtest "partial success" => sub {
    plan 5;
    run-test-incomplete Q{hello there, 'world}, ('hello', 'there,', Q{'world});
    run-test-incomplete Q{hello there, "world}, ('hello', 'there,', Q{"world});
    run-test-incomplete Q{hello there, world\}, ('hello', 'there,', Q{world\});
    run-test-incomplete Q{hello there, world'}, ('hello', 'there,', Q{world'});
    run-test-incomplete Q{hello there, world"}, ('hello', 'there,', Q{world"});
}


sub run-tests(*@tests) {
    plan +@tests;
    is-deeply
            shell-words(.key),
            .value,
            "｢{.key}｣".subst("\n", '␤', :g)
        for @tests;
}

sub run-test-incomplete($input, @output) {
    subtest "｢$input｣".subst("\n", '␤', :g) => sub {
        plan 5;
        my @words;
        lives-ok { @words = shell-words $input }, "shell-words lives";
        is-deeply @words.head(*-1), @output.head(*-1),
            "initial words are intact";
        fails-like { @words.tail }, X::Text::ShellWords::Incomplete,
            "final word fails as Incomplete";
        ok @words.tail.handled, "failure has been handled";
        is @words.tail.Str, @output.tail, "final word stringifies OK";
    }
}

# vi:ft=raku
