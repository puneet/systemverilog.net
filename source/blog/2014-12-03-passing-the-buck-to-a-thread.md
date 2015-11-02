---
title: Passing the buck to a thread
layout: article
author: ritu
modified: 2014-11-22
tags: fork, concurrency, UVM
---

Hardware is concurrent by nature. And so are testbenches.

In context of UVM, the `run_phase` of each testbench component, executes concurrently with other components. Forking a separate thread for each `uvm_component` is handled by the UVM base class library; the user does not have to explicitly invoke fork.

There are other situations however (*eg a virtual sequence*), where you might be required to spawn a thread explicitly. Think of a scenario where you have multiple sequences streaming over a number of TLM blocking ports. And you are modeling a packet router that picks up packets from each of the streams continuously, and routes them to one or more egress ports. A single thread can not simultaneously wait on multiple blocking ports. You need to fork multiple threads, each one of them listening to the port it has been assigned to. You may want to use a `fork .. join_none` pair:

```systemverilog
for(int index=0; index != ingress_ports.size(); ++index) begin
   fork
      // process an ingress port
   join_none
end
```

So far so good. But we need to tell each of the spawned threads, as to which port it should latch on to. As we do that, we enter the arcane world of concurrency:

```systemverilog
for(int index=0; index != ingress_ports.size(); ++index) begin
   fork
      begin
	 $display("Starting thread %0d at time %2t", index, $time);
         // process an ingress port
      end
   join_none
end
```

This code results in output such as (assuming there are 8 ingress ports):

```
# Starting thread 8 at time  0
# Starting thread 8 at time  0
# Starting thread 8 at time  0
# Starting thread 8 at time  0
# Starting thread 8 at time  0
# Starting thread 8 at time  0
# Starting thread 8 at time  0
# Starting thread 8 at time  0
```

Seems we have encountered a concurrency pitfall!

## What happened!

It turns out that when SystemVerilog executes a `fork`, it simply *registers* the `begin .. end` blocks (and sequential statements, if any) it encounter in the body of the fork with the simulator, as threads. It does not start running these threads yet. Remember that SystemVerilog simulator runs only one thread at a time. And when the fork statement is encountered, the simulator will not start running the registered threads until the parent thread (the thread that encountered the fork statement) yields.

In case a `fork` is paired with either `join` or `join_any`, the parent thread yields immediately. The control of the simulation goes back to the scheduler, and it starts executing waiting threads from a list of executable threads corresponding to the current time stamp. This list would also have the threads registered by the `fork` statement that was just encountered.

But we used `join_none`. We wanted to simultaneously spawn a number of threads counted by the enveloping `for` loop. Since `fork .. join_none` does not yield (you can even use `fork .. join_none` inside an SV function), the execution of the `for` loop continues till `index` hits the count of the ingress ports. As a result, when the forked threads get a chance to execute, the `index` has already hit a value of 8.

## Explicitly wait; but should we?

And so, we need to make the parent thread yield, before the `index` is incremented. We can easily do that by introducing an explicit wait:

```systemverilog
for(int index=0; index != ingress_ports.size(); ++index) begin
   fork
      begin
	 // process an ingress port
	 $display("Starting thread %0d at time %2t", index, $time);
      end
   join_none
   #0;
end
```

This results in:

```
VSIM 1> run -all

# Starting thread 0 at time  0
# Starting thread 1 at time  0
# Starting thread 2 at time  0
# Starting thread 3 at time  0
# Starting thread 4 at time  0
# Starting thread 5 at time  0
# Starting thread 6 at time  0
# Starting thread 7 at time  0
```

Though we have achieved the objective we had set for ourselves, we have introduced explicit delta delays in the code. Explicit delta delays can give rise to race conditions. Moreover, the forked threads still share the `index` variable with the main thread. Our achievment is illusionary. The snippet displays the right value for `index` since the `$display` call happens right in the beginning. Should we try to access `index` after a delay or a blocking TLM port access, `index` would again read 8 for any of these threads!

## Each thread its own index

With our present code, all the threads are looking at the shared variable `index`. With concurrency in mind, we need to pass a *different* `index` to each thread. We can do that by creating a local scope exclusive to each of the forked threads. To achieve that we can create a SystemVerilog function enveloping the `fork .. join_none` statement. Here we go:

```systemverilog
task run_phase(uvm_phase phase);
   for(int index=0; index != ingress_ports.size(); ++index) begin
      spawn_router_thread(index);
   end
endtask

function void spawn_router_thread(int index);
   fork
      begin
         // process an ingress port
         $display("Starting thread %0d at time %2t", index, $time);
      end
   join_none
endfunction
```

```
VSIM 1> run -all

# Starting thread 7 at time  0
# Starting thread 6 at time  0
# Starting thread 5 at time  0
# Starting thread 4 at time  0
# Starting thread 3 at time  0
# Starting thread 2 at time  0
# Starting thread 1 at time  0
# Starting thread 0 at time  0
```

## Localised fork variable

The same result can also be achieved by declaring a localized variable in the *declarative region* of the `fork .. join_none` block. The declarative region starts right below the keyword `fork` (and the optional label it might have). Any declaration made here results in allocation of storage for the variables declared. The allocation happens each time the `fork` statement is encountered at runtime. Any assignments made in this region is executed immediately when the `fork` is encountered. As a result our local variable `_index` gets the right value of the `index` as the `for` loop executes. The keyword `automatic` can be omitted if we are already inside a `class` scope.

```systemverilog
for(int index=0; index != ingress_ports.size(); ++index) begin
   fork
      automatic int _index = index;
      begin
	 // process an ingress port
	 $display("Starting thread %0d at time %2t", _index, $time);
      end
   join_none
end
```


```
VSIM 1> run -all

# Starting thread 7 at time  0
# Starting thread 6 at time  0
# Starting thread 5 at time  0
# Starting thread 4 at time  0
# Starting thread 3 at time  0
# Starting thread 2 at time  0
# Starting thread 1 at time  0
# Starting thread 0 at time  0
```
