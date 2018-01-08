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
-export([start/2, server/3, producer/1, consumer/1, count/2]).


count(N, ThousandsCounter) ->
  receive
    X ->
      if
        N >= 1000 ->
          io:format("Yeah! We have produced ~p elements!~n", [ThousandsCounter]),
          count(0, ThousandsCounter + 1000);
        true -> count(N + X, ThousandsCounter)
      end
  end.

%%
server(Buffer, Capacity, CountPid) ->
  receive
%%    PRODUCER
    {Pid, produce, InputList} ->
      NumberProduce = lists:flatlength(InputList),
      case canProduce(Buffer, NumberProduce, Capacity) of
        true ->
          NewBuffer = append(InputList, Buffer),
          CountPid ! lists:flatlength(InputList),
          Pid ! ok,
          server(NewBuffer,Capacity, CountPid);
        false ->
          Pid ! tryagain,
          server(Buffer, Capacity, CountPid)
      end;

%%    CONSUMER
    {Pid, consume, Number} ->
      case canConsume(Buffer, Number) of
        true ->
          Data = lists:sublist(Buffer, Number),
          NewBuffer = lists:subtract(Buffer, Data),
          Pid ! {ok, Data},
          server(NewBuffer, Capacity,CountPid);
        false ->
          Pid ! tryagain,
          server(Buffer, Capacity, CountPid)

      end
  end.



producer(ServerPid) ->
  X = rand:uniform(9),
  ToProduce = [rand:uniform(500) || _ <- lists:seq(1, X)],
  ServerPid ! {self(),produce,ToProduce},

  receive
    _ -> producer(ServerPid)
  end.




consumer(ServerPid) ->
  X = rand:uniform(9),
  ServerPid ! {self(),consume,X},

  receive
    _ -> consumer(ServerPid)
  end.

spawnProducers(Number, ServerPid) ->
  case Number of
    0 -> io:format("Spawned producers");
    N ->
      spawn(zad2,producer,[ServerPid]),
      spawnProducers(N - 1,ServerPid)
  end.

spawnConsumers(Number, ServerPid) ->
  case Number of
    0 -> io:format("Spawned producers");
    N ->
      spawn(zad2,consumer,[ServerPid]),
      spawnProducers(N - 1,ServerPid)
  end.

start(ProdsNumber, ConsNumber) ->
  CountPid = spawn(zad2, count, [0,0]),

  ServerPid = spawn(zad2,server,[[],20, CountPid]),

  spawnProducers(ProdsNumber, ServerPid),
  spawnConsumers(ConsNumber, ServerPid),

  timer:kill_after(5000, ServerPid).

canProduce(Buffer, Number, Capacity) ->
  lists:flatlength(Buffer) + Number =< Capacity.

canConsume(Buffer, Number) ->
  lists:flatlength(Buffer) >= Number.


append([H|T], Tail) ->
  [H|append(T, Tail)];
append([], Tail) ->
  Tail.

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