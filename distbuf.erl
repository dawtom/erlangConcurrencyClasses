%%%-------------------------------------------------------------------
%%% @author Dawid Tomasiewicz
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. sty 2018 10:33
%%%-------------------------------------------------------------------
-module(distbuf).
-author("Dawid Tomasiewicz").

%% FIXME make getting buffer more random (now it takes first only in fact)


%% API
-export([start/2, server/3, producer/1, consumer/1, count/2, partialBuffer/1, setnth/3]).


count(N, ThousandsCounter) ->
  receive
    X ->
      if
        N >= 1000 ->
          io:format("Yeah! We have already produced ~p elements!~n", [ThousandsCounter]),
          count(0, ThousandsCounter + 1000);
        true -> count(N + X, ThousandsCounter)
      end
  end.

server(BuffersList, CountPid, Capacity) ->
%%  io:format("Buffers list: ~p~n", [BuffersList]),
  receive
    {Pid, produce, InputList} ->
%%      io:format("Producing~n"),
      BufferPid = getBufferPidToProduce(shuffle(BuffersList), InputList, Capacity),
      case BufferPid of
        0 ->
          Pid ! tryagain,
          server(BuffersList, CountPid, Capacity);
        GoodPid ->
          GoodPid ! {self(), produce, InputList},
          receive
%%        I need to be careful for pattern matching here, I must not match pattern from external receive
            ok ->
              Len = lists:flatlength(InputList),
              CountPid ! Len,
              Pid ! ok,
              %%      TODO uncomment lines below to show behaviour of my system
%%              io:format("Buffers after producing list: ~p~n", [BuffersList]),
              server(getUpdatedBufferList(BuffersList, GoodPid, Len), CountPid, Capacity)
          end
      end;


    {Pid, consume, Number} ->
%%      io:format("Consuming~n"),
      BufferPid = getBufferPidToConsume(shuffle(BuffersList), Number, Capacity),
      case BufferPid of
        0 ->
          Pid ! tryagain,
          server(BuffersList, CountPid, Capacity);
        GoodPid ->
          GoodPid ! {self(), consume, Number},
          receive
%%        I need to be careful for pattern matching here, I must not match pattern from external receive

            {ok, Data} ->
              Pid ! {ok, Data},
              %%      TODO uncomment lines below to show behaviour of my system
%%              io:format("Buffers after consuming: ~p~n", [BuffersList]),
              server(getUpdatedBufferList(BuffersList, GoodPid, -Number), CountPid, Capacity)
          end
      end
  end.

getUpdatedBufferList([{BufferPid, NumberOfElements}|Tail], GoodPid, Number) ->
  Index = getIndex(1,[{BufferPid, NumberOfElements}|Tail], GoodPid),
  Res = setnth(Index
    , [{BufferPid, NumberOfElements}|Tail],
    {GoodPid, getnth(Index,[{BufferPid, NumberOfElements}|Tail]) + Number}),
%%  io:format("setnth(~p,~p,~p)~n",[getIndex(1,[{BufferPid, NumberOfElements}|Tail], GoodPid),
%%    [{BufferPid, NumberOfElements}|Tail], {BufferPid, NumberOfElements + Number}]),
%%  io:format("Number: ~p :: Res: ~p~n", [Number,Res]),
  Res.

getIndex(Iterator, [{BufferPid, _}|Tail], GoodPid) ->
  case BufferPid of
    GoodPid ->
      Iterator;
    _ -> getIndex(Iterator + 1, Tail, GoodPid)
  end.

getnth(1, [{Pid,Value}|Rest]) -> Value;
getnth(I, [E|Rest]) -> getnth(I-1, Rest).


setnth(1, [_|Rest], New) -> [New|Rest];
setnth(I, [E|Rest], New) -> [E|setnth(I-1, Rest, New)].

%% BuffersList contains information about all buffers. It is a list of tuples:
%%  {Pid, NumberOfElements}
%% Functions getBufferPidToProduce and getBufferPidToConsume return buffer pid
getBufferPidToProduce([], _,_) -> 0;
getBufferPidToProduce([{Pid, HowManyFilled}|Tail], InputList, Capacity) ->
  case canProduce(HowManyFilled, lists:flatlength(InputList), Capacity) of
    false ->
%%      io:format("Cannot produce: filled: ~p, listlen: ~p, capacity: ~p~n", [HowManyFilled,
%%        lists:flatlength(InputList), Capacity]),
      getBufferPidToProduce(Tail, InputList, Capacity);
    true ->
%%      TODO uncomment two lines below to show behaviour of my system
%%      io:format("Will produce: filled: ~p, listlen: ~p, capacity: ~p~n", [HowManyFilled,
%%        lists:flatlength(InputList), Capacity]),
      Pid
  end.

shuffle(List) ->
  %% Determine the log n portion then randomize the list.
  randomize(round(math:log(length(List)) + 0.5), List).

randomize(1, List) ->
  randomize(List);
randomize(T, List) ->
  lists:foldl(fun(_E, Acc) ->
    randomize(Acc)
              end, randomize(List), lists:seq(1, (T - 1))).

randomize(List) ->
  D = lists:map(fun(A) ->
    {random:uniform(), A}
                end, List),

  {_, D1} = lists:unzip(lists:keysort(1, D)),
  D1.

getBufferPidToConsume([], _,_) -> 0;
getBufferPidToConsume([{Pid, HowManyFilled}|Tail], Number, Capacity) ->
  case canConsume(HowManyFilled, Number) of
    false ->
%%      io:format("Cannot consume: filled: ~p, listlen: ~p, capacity: ~p~n", [HowManyFilled,
%%        Number, Capacity]),
      getBufferPidToConsume(Tail, Number, Capacity);
    true ->
      %%      TODO uncomment lines below to show behaviour of my system
%%      io:format("Will consume: filled: ~p, listlen: ~p, capacity: ~p~n", [HowManyFilled,
%%        Number, Capacity]),
      Pid
  end.

partialBuffer(Buffer) ->
  receive
    {ServerPid, produce, ToProduce} ->
      NewBuffer = append(ToProduce, Buffer),
      ServerPid ! ok,
      partialBuffer(NewBuffer);
    {ServerPid, consume, Number} ->
      Data = lists:sublist(Buffer, Number),
      NewBuffer = lists:subtract(Buffer, Data),
      ServerPid ! {ok, Data},
      partialBuffer(NewBuffer)
  end.




producer(ServerPid) ->
  X = rand:uniform(9),
  ToProduce = [rand:uniform(500) || _ <- lists:seq(1, X)],

  actualProduce(ToProduce, ServerPid).


actualProduce(ToProduce, ServerPid) ->
  ServerPid ! {self(),produce,ToProduce},

  receive
    tryagain -> actualProduce(ToProduce, ServerPid);
    ok -> producer(ServerPid)
  end.

consumer(ServerPid) ->
  X = rand:uniform(9),
%%  io:format("Consumer will send ~p elements ~n",[X]),
  actualConsume(ServerPid,X).


actualConsume(ServerPid, Number) ->
  ServerPid ! {self(),consume,Number},

  receive
    tryagain -> actualConsume(ServerPid, Number);
    {ok, Data} -> consumer(ServerPid)
  end.

spawnProducers(Number, ServerPid) ->
  case Number of
    0 -> io:format("Spawned producers");
    N ->
      spawn(distbuf,producer,[ServerPid]),
      spawnProducers(N - 1,ServerPid)
  end.

spawnConsumers(Number, ServerPid) ->
  case Number of
    0 -> io:format("Spawned producers");
    N ->
      spawn(distbuf,consumer,[ServerPid]),
      spawnProducers(N - 1,ServerPid)
  end.

spawnPartialBuffersAndGetListOfThem(1) ->
  [{spawn(distbuf, partialBuffer, [[]]),0}];
spawnPartialBuffersAndGetListOfThem(HowMany) ->
  [{spawn(distbuf, partialBuffer, [[]]),0} | spawnPartialBuffersAndGetListOfThem(HowMany - 1)].

start(ProdsNumber, ConsNumber) ->
  CountPid = spawn(distbuf, count, [0,0]),


%%  List = [{1,15},{2,20},{3,25},{4,30},{5,35}],
%%  NewList = setnth(getIndex(1,List,4),List,{4,33}),
%%  NewList = getUpdatedBufferList(List, 5, -3),
%%  io:format("New list: ~p~n", [NewList]).
  PartialBuffersList = spawnPartialBuffersAndGetListOfThem(10),

  ServerPid = spawn(distbuf,server,[PartialBuffersList,CountPid, 20 ]),
%%
  spawnProducers(ProdsNumber, ServerPid),
  spawnConsumers(ConsNumber, ServerPid).
%%  timer:kill_after(5000, ServerPid).
%%  io:format("Time is up. Program has produces for 5 seconds").

canProduce(HowManyFilled, Number, Capacity) ->
  HowManyFilled + Number =< Capacity.

canConsume(HowManyFilled, Number) ->
  HowManyFilled >= Number.


append([H|T], Tail) ->
  [H|append(T, Tail)];
append([], Tail) ->
  Tail.