Pisco
=====

It is a tiny parse transform, that allows to put an unescaped string inside
a string comment.

It was originally developed for using regular expressions without escaping.

__License__: MIT

__Author__: Uvarov Michael ([`freeakk@gmail.com`](mailto:freeakk@gmail.com))

[![Build Status](https://secure.travis-ci.org/freeakk/pisco.png?branch=master)](http://travis-ci.org/freeakk/pisco)

How it works
============

This `parse_transform` analyzes the `unescaped` attributes and comments abive
them.

```erlang
%Count> Comment
-unescaped(Name).
```

The comment consists of 2 parts, delemited by the greater-than sign (`>`).
The parts are:
The `Count` part contains how many characters to skip after `>`. Skipped 
characters are ignored by the parse transform.
The `Comment` part stores an unescaped string.

The multi-line comments will be join with "".

```erlang
%1> string 1 
%1> string 2 
-unescaped(example).
```

The whitespaces in the end of the string will be ignored.

We recommend to use a funtion for the access of the string:

```erlang
example() -> unescaped(example).
```

The call of this function returns `"string 1string 2"`.

Example 1
---------

Before:

```erlang
parse_date(Str) ->                                     
    RE = "^(\\w*) (\\d{1,2}), (\\d{4})",               
    re:run(Str, RE, [{capture, all, binary}]).
```

After:

```erlang
-compile({parse_transform, pisco}).

%%1> ^(\w*) (\d{1,2}), (\d{4})
-unescaped(re1).
...
parse_date(Str) ->                                     
    re:run(Str, unescaped(re1), [{capture, all, binary}]).
```

