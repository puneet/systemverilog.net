---
title: SystemVerilog Inline Constraint Gotcha
modified: 2014-11-10
tags: constraints, randomize with, variable hiding
author: shankar
layout: article
---

SystemVerilog UVM sequence generates interesting scenerios by randomizing and constraining the data items of the sequence item class.  Generally, the constraints are specified in the sequence item class. But SystemVerilog allows you to add in-line contraints in the sequence body, by using `randomize() with` construct. These in-line constraints are applied in addition to the constraints specified in the sequence item class.

```systemverilog
// Sequence item class
class seq_item extends uvm_sequence_item;
  rand [31:0] addr;
  rand [31:0] data;
endclass

// Sequence class
class seq extends uvm_sequence#(seq_item);
  bit [31:0] addr;

  task body();
    seq_item trans;
    bit [31:0] addr = 32'h11001100;
    assert(trans.randomize() with { trans.addr == addr; });
  endtask
endclass
```

The above code generated a transaction with `addr` as `hbfdf5196`. What did the solver do with the inline `this.addr == addr` constraint?

The problem arises when you try to make `seq_item` address equal to the address in the calling sequence class using the above in-line constraint. The result is undesirable since the constraint will  actually cause the `seq_item` address (trans.addr) to be equal to itself. This gotcha in SystemVerilog arises because we have `addr` as a variable defined in both `seq_item` class as well as the `seq` class. SystemVerilog scoping rules pick the variable which is part of the object being randomized.

The SystemVerilog P1800-2012 LRM (see page 495) states that:

> Unqualified names in an unrestricted in-lined constraint block
> are then resolved by searching first in the scope of the
> randomize() with object class followed by a search of the
> scope containing the method call—the local scope.

In order to overcome the above problem we can prefix `local::` before the address of sequence class `seq`. Thus, we could modify the code as:

```systemverilog
// Sequence item class
class seq_item extends uvm_sequence_item;
  rand [31:0] addr;
  rand [31:0] data;
endclass

// Sequence class
class seq extends uvm_sequence#(seq_item);
  bit [31:0] addr;

  task body();
    seq_item trans;
    bit [31:0] addr = 32'h11001100;
    assert(trans.randomize()
      with { trans.addr == local::addr; });
  endtask
endclass
```

The above code generates the following address:

```
 # Name     Type           Size     Value
 # trans    seq_item       -       @636
 # addr     integral       32      'h11001100

```

This statement makes sure that the constraint solver looks for the address following the local:: only in the local scope (i.e. the address in the sequence class `seq`). So, now the constraint will be the desired one which states that while randoming the address of `seq_item`, the constraint solver should make sure that the address of the seq_item should be equal to the address in the sequence `seq`.
