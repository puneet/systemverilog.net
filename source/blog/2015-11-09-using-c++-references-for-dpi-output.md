---
title: Using C++ references for DPI output
date: 2015-11-09
author: Shankar
author_site: http://coverify.com
tags: DPI, references
layout: article
---
To get an output from a DPI-C function in SystemVerilog, the output can be retrieved as a function return value but a C function can return only a single value. In order to return multiple values an output argument has to be declared. Correspondingly on the C side, the argument has to be declared as a **pointer type**. 

```verilog
module top;

// Declare the DPI import function

import "DPI-C" function int sum(input int a, input int b, output int c);
int j;
   
 initial begin
   sum(10, 20, j);
   $display("j=%d",j);
end

endmodule
```

```C++
#include <stdio.h>

extern "C"
void sum(int a, int b, int *c) {
  *c = a + b;
  printf ("%d\n", c) ;
  return *c;
}
```
When we do that the output variable needs to be dereferenced every time it is used in the function body (coded in C/C++). C++ provides an elegant solution by introducing reference argument declaration. 

```C++
#include <stdio.h>

extern "C"
void sum(int a, int b, int& c) {
  c = a + b;
  printf ("%d\n", c) ;
  return c;
}
```
This not only makes the code uncomplicated but also easy to understand. The feature allowed in C++ but can also be used with DPI in conjunction with output DPI arguments. No change is required in SystemVerilog DPI import declaration. 

