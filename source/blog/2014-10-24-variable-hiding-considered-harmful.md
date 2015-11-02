---
title: Variable hiding considered harmful
date: 2014-10-24
author: puneet
tags: object-orientism, variable-hiding
layout: article
---

Welcome to the brand new SystemVerilog blog!

[DVCon](http://dvcon.org) has gone global this year. This September, Bengaluru witnessed the first edition of [DVCon India](http://dvcon-india.org). And last week Accellera concluded the first [European leg of DVCon](http://dvcon-europe.org) at Munich.

I would have loved to, but could not attend DVCon India. But thanks to the program steering committee, the proceedings of the event have been made available publicly [here](http://dvcon-india.org/proceedings/). You have the option to download all the papers and presentations archived in a zip file or as individual files.

A friend drew my attention to a [poster paper](http://dvcon-india.org/wp-content/uploads/2014/proceedings/posters/Can_Someone_Make_UVM_Easy_Paper.pdf) titled ***Please! Can Someone Make UVM Easy to Use?***. Seemingly, this paper won the best paper poster award at the event.

At the onset, the paper argues that parameterized classes are often misunderstood and misused and result in classes that can not be related via inheritance. The paper notes:  *Polymorphism is one of the main reasons to use classes*. And that when we deploy parameterized classes, polymorphism is a casualty:

```systemverilog
class classValue #(int V = 3);
endclass
classValue #(3) cV3 = new();
classValue #(4) cV4 = new();
cV3 = cV4; // ERROR
```

Ok. So that is expected since the type of `cV3` and that of `cV4` do not match. To retain type compatibility, the paper tells us to rewrite the above code as:

```systemverilog
class classValue;
  int V = 3;
endclass
class classValueNew extends classValue;
  int V = 4;
endclass
classValue cV = new;
classValueNew cVN = new;
cV = cVN;
```

Whoa! It is a classic example of variable hiding. Variable hiding breaks polymorphism, and polymorphism is what we wanted to enable in the first place. Consider:

```systemverilog
classValueNew cVN = new;
classValue cV = cVN;

$display("V is %d", cV.V);     // prints "V is 3"
$display("V is %d", cVN.V);    // prints "V is 4"

if(cV == cVN)
  $display("cV equals cVN");   // prints "cV equals cVN"
```

Though `cV` is the same object as `cVN`, `cV.V` returns a different value compared to `cVN.V`, and would result in a major source of confusion and diffcult to find bugs. The [official java documentation](http://docs.oracle.com/javase/tutorial/java/IandI/hidevariables.html) too discourages such a coding practice.

Now let us consider what could be done to alleviate the situation. To begin with, we could make `V` local to the class.  This way, we could ensure that `V` can be accessed only by the class methods. Note that class parameters too are available only inside the class.

There is yet another issue that needs consideration. While the class parameters are read-only, the fields that we substituted them with, can be inadvertently modified. To remedy this issue, we can either declare the given field as `const`, or still better, we could make the variable `static const`, thus ensuring that the variable does not take memory space for every object:

```systemverilog
class classValue;
  static const int V = 3;
endclass
class classValueNew extends classValue;
  static const int V = 4;
endclass
classValue cV = new;
classValueNew cVN = new;
cV = cVN;
```

Alternately we could have coded a virtual function that returns the value:

```systemverilog
class classValue;
  virtual function int V(); return 3; endfunction
endclass
class classValueNew extends classValue;
  virtual function int V(); return 4; endfunction
endclass
classValue cV = new;
classValueNew cVN = new;
cV = cVN;
```

The virtual function so declared can be accessed publicly, but that is fine since the function exhibits polymorphic characteristic.
