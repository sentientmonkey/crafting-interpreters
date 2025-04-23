use crate::lox::chunk::{Chunk, Instruction, OpCode};
use crate::lox::scanner::{Scanner, TokenType};
use std::env;

pub type Value = f64;

#[derive(Debug)]
pub enum InterpretError {
    CompileError,
    RuntimeError,
}

pub type InterpretResult = Result<Value, InterpretError>;

const STACK_MAX: usize = 256;

pub struct VM {
    chunk: Chunk,
    ip: usize,
    stack: [Value; STACK_MAX],
    stack_top: usize,
}

macro_rules! unary_op{
    ($vm:expr,$op:tt) => {
        {
            let a = $vm.pop();
            $vm.push($op a);
        }
    }
}
macro_rules! binary_op{
    ($vm:expr,$op:tt) => {
        {
            let a = $vm.pop();
            let b = $vm.pop();
            $vm.push(a $op b);
        }
    }
}

impl VM {
    pub fn new() -> VM {
        VM {
            chunk: Chunk::new(),
            ip: 0,
            stack: [0.0; STACK_MAX],
            stack_top: 0,
        }
    }

    pub fn interpret(&mut self, contents: &str) -> InterpretResult {
        self.compile(contents);
        Ok(0.0)
    }

    fn compile(&mut self, source: &str) {
        let mut scanner = Scanner::new(source);
        let mut line = 0;
        loop {
            let token = scanner.scan_token();
            if line != token.line {
                print!("{:4} ", token.line);
                line = token.line;
            } else {
                print!("   | ");
            }
            println!("{:?}", token.token_type);

            if token.token_type == TokenType::EOF {
                break;
            }
        }
    }

    pub fn run(&mut self) -> InterpretResult {
        let debug = is_debug();
        loop {
            if debug {
                print!("          ");
                for slot in self.stack.iter().take(self.stack_top) {
                    print!("[ ");
                    print!("{}", slot);
                    print!(" ]");
                }
                println!("");
                match self
                    .chunk
                    .disassemble_instruction(self.chunk.instructions.get(self.ip).unwrap(), self.ip)
                {
                    Ok(s) => print!("{}", s),
                    Err(_) => return Err(InterpretError::RuntimeError),
                }
            }
            match self.read_byte().code {
                OpCode::Constant(c) => {
                    let constant = self.read_constant(c);
                    self.push(*constant);
                }
                OpCode::Add => binary_op!(self, +),
                OpCode::Subtract => binary_op!(self, -),
                OpCode::Multiply => binary_op!(self, *),
                OpCode::Divide => binary_op!(self, /),
                OpCode::Negate => unary_op!(self, -),
                OpCode::Return => {
                    return Ok(self.pop());
                }
            }
        }
    }

    fn push(&mut self, value: Value) {
        self.stack[self.stack_top] = value;
        self.stack_top += 1;
    }

    fn pop(&mut self) -> Value {
        self.stack_top -= 1;
        self.stack[self.stack_top]
    }

    fn read_byte(&mut self) -> &Instruction {
        let byte = self.chunk.instructions.get(self.ip).unwrap();
        self.ip += 1;
        byte
    }

    fn read_constant(&self, index: usize) -> &Value {
        self.chunk.constants.get(index).unwrap()
    }
}

fn is_debug() -> bool {
    match env::var("DEBUG") {
        Ok(s) => !s.is_empty() && s != "0",
        Err(_) => false,
    }
}

#[cfg(test)]
mod tests {
    use crate::lox::chunk::Chunk;
    use crate::lox::chunk::OpCode;
    use crate::lox::vm::VM;

    #[test]
    fn it_negates() {
        let mut chunk = Chunk::new();

        let constant = chunk.add_constant(1.2);
        chunk.write_chunk(OpCode::Constant(constant), 123);
        chunk.write_chunk(OpCode::Negate, 123);
        chunk.write_chunk(OpCode::Return, 123);

        let mut vm = VM::new();
        vm.chunk = chunk;

        assert_eq!(-1.2, vm.run().expect("failed"));
    }

    #[test]
    fn it_calculates() {
        let mut chunk = Chunk::new();

        let mut constant = chunk.add_constant(1.2);
        chunk.write_chunk(OpCode::Constant(constant), 123);

        constant = chunk.add_constant(3.4);
        chunk.write_chunk(OpCode::Constant(constant), 123);

        chunk.write_chunk(OpCode::Add, 123);

        constant = chunk.add_constant(5.6);
        chunk.write_chunk(OpCode::Constant(constant), 123);

        chunk.write_chunk(OpCode::Divide, 123);

        chunk.write_chunk(OpCode::Return, 123);

        let mut vm = VM::new();
        vm.chunk = chunk;

        assert_eq!(1.2173913043478262, vm.run().expect("failed"));
    }
}
