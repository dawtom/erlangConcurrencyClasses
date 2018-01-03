%%%-------------------------------------------------------------------
%%% @author lenovo
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. sty 2018 18:55
%%%-------------------------------------------------------------------
-module(zad2).
-author("Dawid Tomasiewicz").

%% API
-export([start/0, server/2]).

server(Buffer, Capacity) ->
  receive
%%    PRODUCER
%%  FIXME no need for number, this is redundancy, may cause problems
    {Pid, produce, Number, InputList} ->

      case canProduce(Buffer, Number, Capacity) of
        true ->
%%          io:format("Producing ~p ~p~n", [Number, InputList]),
          NewBuffer = lists:append(InputList, Buffer),
          Pid ! ok,
          server(NewBuffer,Capacity);
        false ->
%%          io:format("Cannot produce ~p ~p~n", [Number, InputList]),
          Pid ! tryagain,
          server(Buffer, Capacity)
      end;

%%    CONSUMER
    {Pid, consume, Number} ->
      case canConsume(Buffer, Number) of
        true ->
%%          send message with data consumed
%%          io:format("Consuming ~p ~n", [Number]),
          Data = lists:sublist(Buffer, Number),
          NewBuffer = lists:subtract(Buffer, Data),
          Pid ! {ok, Data},
          server(NewBuffer, Capacity);
        false ->
%%          send request to try again
%%          io:format("Cannot consume ~p ~n", [Number]),
          Pid ! tryagain,
          server(Buffer, Capacity)

      end
  end.

canProduce(Buffer, Number, Capacity) ->
  lists:flatlength(Buffer) + Number =< Capacity.

canConsume(Buffer, Number) ->
  lists:flatlength(Buffer) >= Number.

start() ->
  ServerPid = spawn(zad2,server,[[],10]),

  ServerPid ! {self(),produce,5,[1,4,9,16,25]},
  receive
    Something1 -> io:format("Produce 5: ~p~n", [Something1])
  end,


  ServerPid ! {self(),produce,4,[1,4,9,16]},
  receive
    Something2 -> io:format("Produce 4: ~p~n", [Something2])
  end,

  ServerPid ! {self(),produce,4,[1,4,9,16]},
  receive
    Something3 -> io:format("Produce 4: ~p~n", [Something3])
  end,

  ServerPid ! {self(),consume,3},
  receive
    Something4 -> io:format("Consume 3: ~p~n", [Something4])
  end,

  ServerPid ! {self(),consume,7},
  receive
    Something5 -> io:format("Consume 7: ~p~n", [Something5])
  end,

  ServerPid ! {self(),consume,6},
  receive
    Something6 -> io:format("Consume 6: ~p~n", [Something6])
  end.



%%  io:format("~p~n", [canProduce([1,2,3,4], 5,9)]).


append([H|T], Tail) ->
  [H|append(T, Tail)];
append([], Tail) ->
  Tail.