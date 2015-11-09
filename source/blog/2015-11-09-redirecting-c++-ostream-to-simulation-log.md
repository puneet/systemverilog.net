---
title: Redirecting C++ ostream to simulation log file
modified: 2015-11-09
layout: article
author: geeta
tags: vpi_printf, DPI, C++
author_site: http://coverify.com
---
Reference models used in functional verification are often written in C++. Such models are integrated in systemverilog testbenches using DPI. When coding in C++ you want to use streaming operator to print messages or errors. When `std::cout` is used the output goes on terminal and not in the log file. Verilog PLI provides `vpi_printf` to get the output on the terminal. To make it compatible with streaming operator, create a wrapper in C++ as given below:

```cpp
#include <sstream>
#include "vpi_user.h"
class Logger: public std::ostream
{
  class LoggerBuf: public std::stringbuf {
    std::ostream&   output;
    std::stringstream stream;
  public:
    LoggerBuf(): output(stream) {}
    virtual int sync ( ) {       
      std::istringstream iss(str());
      std::stringstream oss;
      std::string prefix = "[CPP_MODEL";
      for (std::string line; std::getline(iss, line); ) {
	oss << prefix << "] ";
	oss << line << "\n";
      }
      vpi_printf((char*) oss.str().c_str());
      str("");
      return 0;
    }
  };
  static Logger* _logger;
  LoggerBuf _buffer;
  Logger() :
    std::ostream(&_buffer),
    _buffer()
  { }
 public:
  static Logger& log() {
    if(_logger == NULL) {
      _logger = new Logger();
    }
    return *_logger;
  }
};
```

You can test the functinality by making a function (foo) in C++ which uses the wrapper:

```cpp
#include <iostream>
#include <stdio.h>
#include "dpi_logger.h"
extern "C" void  foo()
{
  std::cout << "using cout" << std::endl;
  Logger::log() << "Inside foo function" << std::endl;
}
Logger* Logger::_logger;
```

The following code illustrates its usage. Make a  dpi call inside systemverilog program block, and call foo function:

```systemverilog
program logger_test();
   import "DPI-C" function void  foo ();
   initial
     begin
       $display("program block: Interacting with dpi");
       foo();
     end
endprogram // dpi_test
```
