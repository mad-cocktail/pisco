-module(pisco).
-export([parse_transform/2]).


parse_transform(Forms, _Options) ->
    case extract_unescaped_commands(Forms) of
        [] -> Forms;
        UnEscAttrs ->
            Comments = read_comments(Forms),
            ReF = fun erl_recomment:recomment_tree/2,
            {CommentedAttrs, _RemainedComments} = 
                lists:mapfoldl(ReF, Comments, UnEscAttrs),
            Rules = [decode_unescape_attribute(X) || X <- CommentedAttrs],
            F = local_function(unescaped, 1, unescaped_trans(Rules)),
            X = [postorder(F, Tree) || Tree <- Forms],
%           io:format(user, "Rules: ~p~n", [ Rules ]),
%           io:format(user, "Before:\t~p\n\nAfter:\t~p\n", [Forms, X]),
            X
    end.


-record(unescaped_attribute, {name, text}).
decode_unescape_attribute(Node) ->
    Comments = erl_syntax:get_precomments(Node),
    Args     = erl_syntax:attribute_arguments(Node),
    %% Decode `-undescaped(Name).'
    Name =
        case Args of
            [NameTree] ->
                erl_syntax:atom_value(NameTree)
        end,
    Strings = lists:flatmap(fun erl_syntax:comment_text/1, Comments),
    DecodedStrings = [decode_string(X) || X <- Strings],
    #unescaped_attribute{
        name = Name,
        text = string:join(DecodedStrings, "")
    }.


decode_string(Str) ->
    Ms = re:run(Str, "%*(\\d*)>(.*)", [{capture, all_but_first, list}]),
    case Ms of
        {match, [CountStr, StrAfterGt]} ->
            %% This variable stores how many characters to skip from the 
            %% beginning of StrAfterGt.
            Count = list_to_integer(CountStr),
            %% Get a suffix.
            lists:nthtail(Count, StrAfterGt);
        %% It is an usual comment.
        nomatch ->
            ""
    end.


postorder(F, Form) ->
    NewTree =
        case erl_syntax:subtrees(Form) of
        [] ->
            Form;
        List ->
            Groups = [handle_group(F, Group) || Group <- List],
            Tree2 = erl_syntax:update_tree(Form, Groups),
            Form2 = erl_syntax:revert(Tree2),
            Form2
        end,
    F(NewTree).


local_function(FunName, FunArity, TransFun) ->
    fun(Node) ->
        IsFun = erl_syntax:type(Node) =:= application
            andalso always(Op = erl_syntax:application_operator(Node))
            andalso erl_syntax:type(Op) =:= atom
            andalso erl_syntax:atom_value(Op) =:= FunName
            andalso application_arity(Node) =:= FunArity,
            
        if IsFun -> TransFun(Node);
            true -> Node
            end
        end.
        
always(_) -> true.

application_arity(AppNode) ->
    length(erl_syntax:application_arguments(AppNode)).
        
handle_group(F, Group) ->
    [postorder(F, Subtree) || Subtree <- Group].

extract_file_name(Forms) ->
    [F || F <- Forms, erl_syntax:type(F) =:= attribute,
          erl_syntax:atom_value(erl_syntax:attribute_name(F)) =:= file].

extract_unescaped_commands(Forms) ->
    [F || F <- Forms, erl_syntax:type(F) =:= attribute,
          erl_syntax:atom_value(erl_syntax:attribute_name(F)) =:= unescaped].

%% From here: http://erlang.org/pipermail/erlang-questions/2012-July/067921.html
read_comments(Forms) ->
    [FileAttr|_OtherFiles] = extract_file_name(Forms),
    {FileName, _LineNo} = erl_syntax_lib:analyze_file_attribute(FileAttr),
    erl_comment_scan:file(FileName).

unescaped_trans(Rules) ->
    fun(Node) ->
        [NameTree] = erl_syntax:application_arguments(Node),
        Name = erl_syntax:atom_value(NameTree),
        Rec = lists:keyfind(Name, #unescaped_attribute.name, Rules),
        #unescaped_attribute{text = Text} = Rec,
        erl_syntax:string(Text)
        end.

