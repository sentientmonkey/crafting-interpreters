use crate::lox::chunk::{Chunk, Instruction, OpCode};
use crate::lox::compiler::{compile, ParserError};
use crate::lox::scanner::TokenType;
use crate::lox::value::Value;

use std::env;
use std::fmt::Write;

#[derive(Debug, PartialEq)]
pub enum InterpretError {
    CompileError(String),
    RuntimeError(String),
}

pub type InterpretResult = Result<Value, InterpretError>;

const STACK_MAX: usize = 256;

#[derive(Debug)]
pub struct VM {
    chunk: Chunk,
    ip: usize,
    stack: [Value; STACK_MAX],
    stack_top: usize,
}

macro_rules! unary_op{
    ($vm:expr,$op:tt) => {
        {
            let a = $vm.pop().as_number();
            if a.is_err() {
                return Err(InterpretError::RuntimeError(String::from("Operand must be number.")))
            }
            $vm.push(Value::Number($op a.unwrap()));
        }
    }
}
macro_rules! binary_op{
    ($vm:expr,$op:tt) => {
        {
            let b = $vm.pop().as_number();
            let a = $vm.pop().as_number();
            if a.is_err() || b.is_err() {
                return Err(InterpretError::RuntimeError(String::from("Operands must be numbers.")));
            }
            $vm.push(Value::from(a.unwrap() $op b.unwrap()));
        }
    }
}

impl VM {
    pub fn new() -> VM {
        VM {
            chunk: Chunk::new(),
            ip: 0,
            stack: [Value::Number(0.0); STACK_MAX],
            stack_top: 0,
        }
    }

    fn reset_stack(&mut self) {
        self.ip = 0;
        self.stack_top = 0;
    }

    pub fn interpret(&mut self, contents: &str) -> InterpretResult {
        match compile(contents) {
            Ok(c) => {
                self.chunk = c;
                self.run()
            }
            Err(e) => {
                let msg = VM::format_err(e).unwrap();
                Err(InterpretError::CompileError(msg))
            }
        }
    }

    pub fn run(&mut self) -> InterpretResult {
        self.reset_stack();
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
                    Err(e) => {
                        eprintln!("{:?}", e);
                        return Err(InterpretError::RuntimeError("error".to_string()));
                    }
                }
            }
            match self.read_byte().code {
                OpCode::Constant(c) => {
                    let constant = self.read_constant(c);
                    self.push(*constant);
                }
                OpCode::True => self.push(Value::Bool(true)),
                OpCode::False => self.push(Value::Bool(false)),
                OpCode::Equal => {
                    let a = self.pop();
                    let b = self.pop();
                    self.push(Value::Bool(a == b));
                }
                OpCode::Greater => binary_op!(self, >),
                OpCode::Less => binary_op!(self, <),
                OpCode::Nil => self.push(Value::Nil),
                OpCode::Add => binary_op!(self, +),
                OpCode::Subtract => binary_op!(self, -),
                OpCode::Multiply => binary_op!(self, *),
                OpCode::Divide => binary_op!(self, /),
                OpCode::Negate => unary_op!(self, -),
                OpCode::Not => {
                    let v = self.pop();
                    self.push(Value::Bool(v.is_falsey()));
                }
                OpCode::Return => {
                    return Ok(self.pop());
                }
            }
        }
    }

    pub fn format_err(error: ParserError) -> Result<String, std::fmt::Error> {
        let mut output = String::new();
        if error.token.is_some() {
            let token = error.token.clone().unwrap();
            write!(output, "[line {}] Error", token.line)?;
            match error.token.clone().unwrap().token_type {
                TokenType::EOF => write!(output, " at end")?,
                TokenType::Error(e) => write!(output, "{}", e)?,
                _ => writeln!(output, " at '{:?}'", token)?,
            }

            writeln!(output, ": {}", error.message)?;
        } else {
            writeln!(output, "Error: {}", error.message)?;
        }

        Ok(output)
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
    use crate::lox::value::Value;
    use crate::lox::vm::*;

    fn assert_interpret(source: &str, expected_value: &Value) {
        let mut vm = VM::new();
        let result = vm.interpret(source).expect("failed");
        assert_eq!(expected_value, &result, "failed with: {}", source);
    }

    #[test]
    fn it_negates() {
        let mut chunk = Chunk::new();

        let constant = chunk.add_constant(Value::Number(1.2));
        chunk.write_chunk(OpCode::Constant(constant), 123);
        chunk.write_chunk(OpCode::Negate, 123);
        chunk.write_chunk(OpCode::Return, 123);

        let mut vm = VM::new();
        vm.chunk = chunk;

        assert_eq!(Value::Number(-1.2), vm.run().expect("failed"));
    }

    #[test]
    fn it_calculates() {
        let mut chunk = Chunk::new();

        let mut constant = chunk.add_constant(Value::Number(1.2));
        chunk.write_chunk(OpCode::Constant(constant), 123);

        constant = chunk.add_constant(Value::Number(3.4));
        chunk.write_chunk(OpCode::Constant(constant), 123);

        chunk.write_chunk(OpCode::Add, 123);

        constant = chunk.add_constant(Value::Number(5.6));
        chunk.write_chunk(OpCode::Constant(constant), 123);

        chunk.write_chunk(OpCode::Divide, 123);

        chunk.write_chunk(OpCode::Return, 123);

        let mut vm = VM::new();
        vm.chunk = chunk;

        assert_eq!(Value::Number(0.8214285714285714), vm.run().expect("failed"));
    }

    #[test]
    fn it_cannot_add_non_numbers() {
        let mut chunk = Chunk::new();

        let mut constant = chunk.add_constant(Value::Number(1.2));
        chunk.write_chunk(OpCode::Constant(constant), 123);

        constant = chunk.add_constant(Value::Bool(false));
        chunk.write_chunk(OpCode::Constant(constant), 123);

        chunk.write_chunk(OpCode::Add, 123);

        let mut vm = VM::new();
        vm.chunk = chunk;

        let expected = Err(InterpretError::RuntimeError(String::from(
            "Operands must be numbers.",
        )));

        assert_eq!(expected, vm.run());
    }

    #[test]
    fn it_cannot_negate_non_numbers() {
        let mut chunk = Chunk::new();

        let constant = chunk.add_constant(Value::Nil);
        chunk.write_chunk(OpCode::Constant(constant), 123);
        chunk.write_chunk(OpCode::Negate, 123);

        let mut vm = VM::new();
        vm.chunk = chunk;

        let expected = Err(InterpretError::RuntimeError(String::from(
            "Operand must be number.",
        )));

        assert_eq!(expected, vm.run());
    }

    #[test]
    fn it_can_run_true() {
        assert_interpret("true", &Value::Bool(true))
    }

    #[test]
    fn it_can_run_false() {
        assert_interpret("false", &Value::Bool(false))
    }

    #[test]
    fn it_can_run_nil() {
        assert_interpret("nil", &Value::Nil)
    }

    #[test]
    fn it_can_run_not() {
        assert_interpret("!nil", &Value::Bool(true))
    }

    #[test]
    fn it_can_eval_not_nil() {
        assert_interpret("!nil", &Value::Bool(true))
    }

    #[test]
    fn it_can_eval_equality() {
        assert_interpret("5 == 5", &Value::Bool(true));
        assert_interpret("5 == 4", &Value::Bool(false));
        assert_interpret("5 == nil", &Value::Bool(false));
        assert_interpret("nil == nil", &Value::Bool(true));
        assert_interpret("true == false", &Value::Bool(false));
        assert_interpret("true == true", &Value::Bool(true));
        assert_interpret("false == false", &Value::Bool(true));
    }

    #[test]
    fn it_can_compare_values() {
        assert_interpret("5 > 4", &Value::Bool(true));
        assert_interpret("5 >= 5", &Value::Bool(true));
        assert_interpret("4 < 5", &Value::Bool(true));
        assert_interpret("5 <= 5", &Value::Bool(true));
    }

    #[test]
    fn it_can_eval_logical_expressions() {
        assert_interpret("!(5 - 4 > 3 * 2 == !nil)", &Value::Bool(true))
    }
}
