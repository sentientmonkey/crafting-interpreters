use crate::lox::chunk::{Chunk, OpCode};
use std::env;
use std::fmt::Write;

pub type Value = f64;

#[derive(Debug)]
pub enum InterpretError {
    CompileError,
    RuntimeError,
}

pub type InterpretResult = Result<Value, InterpretError>;

const STACK_MAX: usize = 256;

pub struct VM {
    chunks: Vec<Chunk>,
    values: Vec<Value>,
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
            chunks: vec![],
            values: vec![],
            ip: 0,
            stack: [0.0; STACK_MAX],
            stack_top: 0,
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
                match self.disassemble_instruction(self.chunks.get(self.ip).unwrap(), self.ip) {
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

    fn read_byte(&mut self) -> &Chunk {
        let byte = self.chunks.get(self.ip).unwrap();
        self.ip += 1;
        byte
    }

    fn read_constant(&self, index: usize) -> &Value {
        self.values.get(index).unwrap()
    }

    pub fn add_constant(&mut self, value: f64) -> usize {
        let constant = self.values.len();
        self.values.push(value);
        constant
    }

    pub fn write_chunk(&mut self, code: OpCode, line: usize) {
        self.chunks.push(Chunk::new(code, line));
    }

    pub fn disassemble(&self, name: &str) -> Result<String, std::fmt::Error> {
        let mut output = String::from("");
        writeln!(output, "== {} ==", name)?;
        for (offset, chunk) in self.chunks.iter().enumerate() {
            write!(output, "{}", self.disassemble_instruction(chunk, offset)?)?;
        }
        Ok(output)
    }

    fn disassemble_instruction(
        &self,
        chunk: &Chunk,
        offset: usize,
    ) -> Result<String, std::fmt::Error> {
        let mut output = String::new();
        write!(output, "{:04} ", offset)?;

        if offset > 0 && chunk.line == self.chunks.get(offset - 1).unwrap().line {
            write!(output, "   | ")?;
        } else {
            write!(output, "{:4} ", chunk.line)?;
        }

        output.push_str(self.disassemble_chunk(chunk)?.as_str());

        Ok(output)
    }

    fn disassemble_chunk(&self, chunk: &Chunk) -> Result<String, std::fmt::Error> {
        Ok(match chunk.code {
            OpCode::Constant(c) => self.constant_instruction("OP_CONSTANT", c),
            OpCode::Add => self.simple_instruction("OP_ADD"),
            OpCode::Subtract => self.simple_instruction("OP_SUBTRACT"),
            OpCode::Multiply => self.simple_instruction("OP_MULTIPLY"),
            OpCode::Divide => self.simple_instruction("OP_DIVIDE"),
            OpCode::Negate => self.simple_instruction("OP_NEGATE"),
            OpCode::Return => self.simple_instruction("OP_RETURN"),
        }?)
    }

    fn constant_instruction(&self, name: &str, constant: usize) -> Result<String, std::fmt::Error> {
        let mut output = String::from("");
        write!(output, "{:<16} {:4} '", name, constant)?;
        writeln!(output, "{}", self.values.get(constant).unwrap())?;
        Ok(output)
    }

    fn simple_instruction(&self, name: &str) -> Result<String, std::fmt::Error> {
        let mut output = String::from("");
        writeln!(output, "{}", name)?;
        Ok(output)
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
    use crate::lox::vm::OpCode;
    use crate::lox::vm::VM;

    #[test]
    fn it_dissasembles() {
        let expected = "== test chunk ==\n\
                        0000  123 OP_CONSTANT         0 '1.2\n\
                        0001    | OP_RETURN\n";

        let mut vm = VM::new();

        let constant = vm.add_constant(1.2);
        vm.write_chunk(OpCode::Constant(constant), 123);
        vm.write_chunk(OpCode::Return, 123);

        let actual = vm.disassemble("test chunk").expect("Could not write");
        assert_eq!(expected, actual);
    }

    #[test]
    fn it_negates() {
        let mut vm = VM::new();

        let constant = vm.add_constant(1.2);
        vm.write_chunk(OpCode::Constant(constant), 123);
        vm.write_chunk(OpCode::Negate, 123);
        vm.write_chunk(OpCode::Return, 123);

        assert_eq!(-1.2, vm.run().expect("failed"));
    }

    #[test]
    fn it_calculates() {
        let mut vm = VM::new();

        let mut constant = vm.add_constant(1.2);
        vm.write_chunk(OpCode::Constant(constant), 123);

        constant = vm.add_constant(3.4);
        vm.write_chunk(OpCode::Constant(constant), 123);

        vm.write_chunk(OpCode::Add, 123);

        constant = vm.add_constant(5.6);
        vm.write_chunk(OpCode::Constant(constant), 123);

        vm.write_chunk(OpCode::Divide, 123);

        vm.write_chunk(OpCode::Return, 123);

        assert_eq!(1.2173913043478262, vm.run().expect("failed"));
    }
}
