-module(dream_snippets_ffi).
-export([sha256_hex/1, run_program/3, keep_slug_characters/1]).

%% The SHA-256 digest of a text, as 64 lowercase hex digits. GitHub's
%% compare view uses the digest of a file's path as that file's anchor.
sha256_hex(Text) ->
    binary:encode_hex(crypto:hash(sha256, Text), lowercase).

%% Remove each character that is not a letter, a combining mark, a decimal
%% digit, an underscore, a space or a hyphen. Letters and digits of every
%% script are kept. This is the character rule of GitHub's heading anchors.
keep_slug_characters(Text) ->
    re:replace(
        Text,
        <<"[^\\p{L}\\p{M}\\p{Nd}_ -]">>,
        <<>>,
        [global, unicode, ucp, {return, binary}]
    ).

%% Run a program with a list of arguments in a directory, and return its
%% standard output.
%%
%% The program starts directly, not through a shell, so no argument is
%% read by a shell. Standard error is not captured: the program prints it
%% to the terminal. Returns {error, git_not_found} when the program is not
%% on the PATH, and {error, {git_failed, Status, Output}} when it exits with
%% a status that is not 0.
run_program(Program, Directory, Arguments) ->
    case os:find_executable(unicode:characters_to_list(Program)) of
        false ->
            {error, git_not_found};
        Path ->
            Port = open_port(
                {spawn_executable, Path},
                [
                    binary,
                    exit_status,
                    hide,
                    {cd, unicode:characters_to_list(Directory)},
                    {args, Arguments}
                ]
            ),
            collect_output(Port, [])
    end.

collect_output(Port, Chunks) ->
    receive
        {Port, {data, Data}} ->
            collect_output(Port, [Data | Chunks]);
        {Port, {exit_status, 0}} ->
            {ok, iolist_to_binary(lists:reverse(Chunks))};
        {Port, {exit_status, Status}} ->
            {error, {git_failed, Status, iolist_to_binary(lists:reverse(Chunks))}}
    end.
