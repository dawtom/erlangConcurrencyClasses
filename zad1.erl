%%%-------------------------------------------------------------------
%%% @author lenovo
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. gru 2017 13:53
%%%-------------------------------------------------------------------
-module(zad1).

-export([start/0, aFun/1, bFun/1, cFun1/1, cFun2/0, cFun2Count/2, cFun3/0]).

aFun(Cpid) ->
  Cpid ! aaa,
  aFun(Cpid).

bFun(Cpid) ->
  Cpid ! bbb,
  bFun(Cpid).

cFun1(MessageType) ->
  case MessageType of
    receiveFromA  ->
      receive
        aaa ->
          io:format("aaa~n"),
          cFun1(receiveFromB);
        _ ->
          cFun1(receiveFromA)
      end;
    receiveFromB  ->
      receive
        aaa ->
          io:format("b~n"),
          cFun1(receiveFromA);
        _ -> cFun1(receiveFromB)
      end
  end.

cFun2() ->

  receive
    aaa ->
      io:format("aaa ~n"),
      cFun2();
    bbb ->
      io:format("bbb~n"),
      cFun2();
    _ -> io:format("Wrong message~n")

  end.

cFun2Count(ACount,BCount) ->

  receive
    aaa ->
      io:format("aaa ~p~n", [ACount + 1]),
      cFun2Count(ACount + 1, BCount);
    bbb ->
      io:format("bbb ~p~n", [BCount + 1]),
      cFun2Count(ACount, BCount + 1);
    _ -> io:format("Wrong message~n")
  end.

cFun3() ->
  receive
    Variable -> io:format(Variable),
      io:format("~n"),
    cFun3()
  end.



start() ->
  CPid = spawn(zad1, cFun3, []),
  spawn(zad1, aFun, [CPid]),
  spawn(zad1, bFun, [CPid]).
%%  Pong_PID = spawn(hello, pong, []),
%%  spawn(hello, ping, [4, Pong_PID]).