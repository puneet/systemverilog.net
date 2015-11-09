---
title: Using C++ references for DPI output
date: 2015-11-09
author: shankar
author_site: http://coverify.com
tags: DPI, references
layout: article
---
To get a single output from a DPI-C function in SystemVerilog, the output can be returned from the function. In order to return multiple values we need to use output arguments. On the C side, the corresponding arguments have to be declared as pointers. In the follwing example code, we use `c` as an output argument.

```verilog
module top;
  // Declare the DPI import function
  import "DPI-C" function int sum(input int a,
                    input int b, output int c);

  int j;
  initial begin
     sum(10, 20, j);
     $display("j=%d",j);
  end
endmodule
```

```c
#include <stdio.h>

void sum(int a, int b, int *c) {
  *c = a + b;
  printf ("%d\n", *c) ;
  return *c;
}
```
When we do that the output argument variable needs to be dereferenced every time it is used in the function body (coded in C/C++). C++ provides an elegant solution by introducing reference argument declaration. 

```cpp
#include <stdio.h>

extern "C"
void sum(int a, int b, int& c) {
  c = a + b;
  printf ("%d\n", c) ;
  return c;
}
```
Using reference arguments not only unclutters the code, but also makes the code easy to understand. Reference arguments are a C++ feature but can also be used with DPI in conjunction with output DPI arguments, since under the hood C++ compilers implement reference arguments as pointers only. No change is required in SystemVerilog DPI import declaration. 

