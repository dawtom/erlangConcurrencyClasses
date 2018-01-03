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
-export([start/0, server/2, producer/1, consumer/1, count/1]).


count(N) ->
  receive
    X ->
      if
        N >= 10000 -> io:format("YEAAAAAH");
        true -> count(N + X)
      end
  end.

%%
server(Buffer, Capacity) ->
%%  io:format("Buffer after: ~p~n", [Buffer]),
  receive
%%    PRODUCER
%%  FIXME no need for number, this is redundancy, may cause problems
    {Pid, produce, InputList} ->
      NumberProduce = lists:flatlength(InputList),
      case canProduce(Buffer, NumberProduce, Capacity) of
        true ->
%%          io:format("Producing ~p ~p~n", [NumberProduce, InputList]),
          NewBuffer = append(InputList, Buffer),
          Pid ! ok,
          server(NewBuffer,Capacity);
        false ->
%%          io:format("Cannot produce ~p ~p~n", [NumberProduce, InputList]),
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

producer(ServerPid) ->
  X = rand:uniform(9),
  ToProduce = [rand:uniform(500) || _ <- lists:seq(1, X)],
  ServerPid ! {self(),produce,ToProduce},
  receive
%%    TODO handle tryagain message
    Message -> io:format("Produce ~p ~p~n", [X,Message])
  end,
  producer(ServerPid).

consumer(ServerPid) ->
  X = rand:uniform(9),
  ServerPid ! {self(),consume,X},
  receive
    Message -> io:format("Consume ~p ~p~n", [X,Message])
  end,
  consumer(ServerPid).

start() ->
  ServerPid = spawn(zad2,server,[[],20]),

  spawn(zad2, count, [0]),
  spawn(zad2, producer, [ServerPid]),
  spawn(zad2, consumer, [ServerPid]).
%%  ServerPid ! {self(),produce,5,[1,4,9,16,25]},
%%  receive
%%    Something1 -> io:format("Produce 5: ~p~n", [Something1])
%%  end,
%%
%%
%%  ServerPid ! {self(),produce,4,[1,4,9,16]},
%%  receive
%%    Something2 -> io:format("Produce 4: ~p~n", [Something2])
%%  end,
%%
%%  ServerPid ! {self(),produce,4,[1,4,9,16]},
%%  receive
%%    Something3 -> io:format("Produce 4: ~p~n", [Something3])
%%  end,
%%
%%  ServerPid ! {self(),consume,3},
%%  receive
%%    Something4 -> io:format("Consume 3: ~p~n", [Something4])
%%  end,
%%
%%  ServerPid ! {self(),consume,7},
%%  receive
%%    Something5 -> io:format("Consume 7: ~p~n", [Something5])
%%  end,
%%
%%  ServerPid ! {self(),consume,6},
%%  receive
%%    Something6 -> io:format("Consume 6: ~p~n", [Something6])
%%  end.



%%  io:format("~p~n", [canProduce([1,2,3,4], 5,9)]).


append([H|T], Tail) ->
  [H|append(T, Tail)];
append([], Tail) ->
  Tail.