---
title: Redirecting C++ ostream to simulation log file
modified: 2015-11-09
layout: article
author: geeta
tags: vpi_printf, DPI, C++
author_site: http://coverify.com
---
Reference models used in functional verification are often written in C++. Such models are integrated in systemverilog testbenches using DPI. When coding in C++ you want to use streaming operator to print messages or errors. When `std::cout` is used the output goes to the terminal but not in the log file. Verilog PLI provides function `vpi_printf`, which has `printf` like functionality, but send the output to verilog log file as well. To make it compatible with streaming output operator, we can create a wrapper in C++:

```cpp
// File dpi_logger.h
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
  static Logger& instance() {
    if(_logger == NULL) {
      _logger = new Logger();
    }
    return *_logger;
  }
};
```

To use the Logger, send the output to the singleton Logger instance:

```cpp
#include <iostream>
#include <stdio.h>
#include "dpi_logger.h"

// static variable instance
// This should be moved to dpi_logger.cpp in real world
Logger* Logger::_logger;

// Logger Usage
extern "C" void  foo()
{
  Logger& log = Logger::instance();

  std::cout << "Message using std::cout" << std::endl;
  log << "Message using Logger" << std::endl;
}
```

To test the code, we make a  dpi call inside systemverilog program block:

```systemverilog
program logger_test();
   import "DPI-C" function void  foo ();
   initial
     begin
       $display("program block: Interacting with dpi");
       foo();
     end
endprogram: logger_test
```
