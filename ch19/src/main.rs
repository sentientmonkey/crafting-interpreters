use crate::lox::vm::{InterpretError, VM};

use std::env;
use std::fs;
use std::io::{self, Write};
use std::process;

pub mod lox;

fn repl(vm: &mut VM) {
    let mut buffer;
    let stdin = io::stdin();
    loop {
        buffer = String::new();
        print!("> ");
        io::stdout().flush().unwrap();
        match stdin.read_line(&mut buffer) {
            Ok(0) => {
                println!("");
                break;
            }
            Ok(_) => match vm.interpret(buffer.as_str()) {
                Err(InterpretError::CompileError(s)) => eprint!("Compile Error: {}", s),
                Err(InterpretError::RuntimeError(s)) => eprint!("Runtime Error: {}", s),
                Ok(v) => println!("{}", v),
            },
            Err(e) => {
                eprintln!("{e}");
                break;
            }
        }
    }
}

fn run_file(vm: &mut VM, path: &str) {
    let contents: String;
    match fs::read_to_string(path) {
        Ok(s) => contents = s,
        Err(e) => {
            eprintln!("Could not open file: {e}");
            process::exit(64);
        }
    }

    match vm.interpret(contents.as_str()) {
        Err(InterpretError::CompileError(s)) => {
            eprintln!("{}", s);
            process::exit(65);
        }
        Err(InterpretError::RuntimeError(s)) => {
            eprintln!("{}", s);
            process::exit(70);
        }
        Ok(v) => println!("{}", v),
    }
}

fn main() {
    let mut vm = VM::new();

    let args: Vec<String> = env::args().collect();
    match args.len() {
        1 => repl(&mut vm),
        2 => run_file(&mut vm, &args[1]),
        _ => {
            eprintln!("Usage: lox [path]");
            process::exit(64);
        }
    }
}
