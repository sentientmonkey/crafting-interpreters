# CHALLENGES

1. Pick an open source implementation of a language you like. Download the source code and poke around in it. Try to find the code that implements the scanner and parser. Are they handwritten, or generated using tools like Lex and Yacc? (.l or .y files usually imply the latter.)

I've looked at [ruby](https://github.com/ruby/ruby) before, but I haven't ever dug into it's parsing and lexing code. It's all dark magic.


2. Just-in-time compilation tends to be the fastest way to implement dynamically typed languages, but not all of them use it. What reasons are there to not JIT?

Defining a JIT seems like a lot of work since you have to come up with a whole bytecode language.

3. Most Lisp implementations that compile to C also contain an interpreter that lets them execute Lisp code on the fly as well. Why?

My best guess would be because dynamic code evaluation.
