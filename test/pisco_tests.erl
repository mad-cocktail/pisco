-module(pisco_tests).

-compile({parse_transform, pisco}).
-compile(export_all).


% v this number means how mush chars (in bytes!) to skip before the real text.
%1> mark1
%  ^ This char will be skipped.
-unescaped(ex1).

%%0>mark2
-unescaped(ex2).

%% With whitespace:
%%1>  mark3
-unescaped(ex3).

%% Multiline:
%%1> mark4.1 
%%          ^ here is a whitespace. It is ignored by the compiler.
%%1>  mark4.2
%%   ^ This whitespace is a part of the text.
-unescaped(ex4).


%% This regex is just an example. 
%% You will have problems, if you want to use this.
%%
%%1> \b[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b
%%
%% Options: case insensitive
-unescaped(check_email).


ex1() ->
    unescaped(ex1).

ex2() ->
    unescaped(ex2).

ex3() ->
    unescaped(ex3).

ex4() ->
    unescaped(ex4).



-include_lib("eunit/include/eunit.hrl").

-ifdef(TEST).

parse_transform_test_() ->
    [ ?_assertEqual(ex1(), "mark1")
    , ?_assertEqual(ex2(), "mark2")
    , ?_assertEqual(ex3(), " mark3")
    , ?_assertEqual(ex4(), "mark4.1 mark4.2")
    ].

re_test_() ->
    [ ?_assertEqual(re:run("test@example.com", 
                           unescaped(check_email),
                           [caseless, {capture, none}]), match)
    , ?_assertEqual(re:run("test#example.com", 
                           unescaped(check_email),
                           [caseless, {capture, none}]), nomatch)
    ].


-endif.
