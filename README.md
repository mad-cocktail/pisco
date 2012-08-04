Pisco
=====

It is a tiny parse transform, that allows to put an unescaped string inside
a string comment.

It was originally developed for using regular expressions without escaping.

__License__: MIT

__Author__: Uvarov Michael ([`freeakk@gmail.com`](mailto:freeakk@gmail.com))

[![Build Status](https://secure.travis-ci.org/freeakk/pisco.png?branch=master)](http://travis-ci.org/freeakk/pisco)

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

