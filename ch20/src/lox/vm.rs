use crate::lox::chunk::{Chunk, Instruction, OpCode};
use crate::lox::compiler::{compile, ParserError};
use crate::lox::interner::Interner;
use crate::lox::scanner::TokenType;
use crate::lox::value::Value;

use std::cell::RefCell;
use std::env;
use std::fmt::Write;
use std::rc::Rc;

#[derive(Debug, PartialEq)]
pub enum InterpretError {
    CompileError(String),
    RuntimeError(String),
}

pub type InterpretResult = Result<String, InterpretError>;

const STACK_MAX: usize = 256;

#[derive(Debug)]
pub struct VM {
    chunk: Chunk,
    ip: usize,
    stack: [Value; STACK_MAX],
    stack_top: usize,
    interner: Rc<RefCell<Interner>>,
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

const DEFAULT_VALUE: Value = Value::Nil;

impl VM {
    pub fn new() -> VM {
        VM {
            chunk: Chunk::new(),
            ip: 0,
            stack: [DEFAULT_VALUE; STACK_MAX],
            stack_top: 0,
            interner: Rc::new(RefCell::new(Interner::default())),
        }
    }

    fn reset_stack(&mut self) {
        self.ip = 0;
        self.stack_top = 0;
    }

    pub fn interpret(&mut self, contents: &str) -> InterpretResult {
        match compile(contents, self.interner.clone()) {
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
                    self.push(constant.clone());
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
                OpCode::Add => {
                    let b = self.pop();
                    let a = self.pop();
                    if a.is_string() && b.is_string() {
                        let s = self.concatinate(&a, &b);
                        self.push(s);
                    } else if a.is_number() && b.is_number() {
                        let n = a.as_number().unwrap() + b.as_number().unwrap();
                        self.push(Value::Number(n));
                    } else {
                        return Err(InterpretError::RuntimeError(String::from(
                            "Operands must be numbers or strings.",
                        )));
                    }
                }
                OpCode::Subtract => binary_op!(self, -),
                OpCode::Multiply => binary_op!(self, *),
                OpCode::Divide => binary_op!(self, /),
                OpCode::Negate => unary_op!(self, -),
                OpCode::Not => {
                    let v = self.pop();
                    self.push(Value::Bool(v.is_falsey()));
                }
                OpCode::Return => {
                    let v = self.pop();
                    let o = match v {
                        Value::String(s) => self.interner.borrow().lookup(s).to_string(),
                        other => format!("{}", other),
                    };

                    return Ok(o);
                }
            }
        }
    }

    fn concatinate(&self, a: &Value, b: &Value) -> Value {
        let s = self
            .interner
            .borrow()
            .lookup(*a.as_string().unwrap())
            .to_string()
            + self.interner.borrow().lookup(*b.as_string().unwrap());

        Value::String(self.interner.borrow_mut().intern(s.as_str()))
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
        self.stack[self.stack_top].clone()
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
    use super::*;

    fn assert_interpret(source: &str, expected_value: &str) -> Rc<VM> {
        let mut vm = VM::new();
        let result = vm.interpret(source).expect("failed");
        assert_eq!(expected_value, &result, "failed with: {}", source);
        Rc::new(vm)
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

        assert_eq!("-1.2", vm.run().expect("failed"));
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

        assert_eq!("0.8214285714285714", vm.run().expect("failed"));
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
            "Operands must be numbers or strings.",
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
        assert_interpret("true", "true");
    }

    #[test]
    fn it_can_run_false() {
        assert_interpret("false", "false");
    }

    #[test]
    fn it_can_run_nil() {
        assert_interpret("nil", "nil");
    }

    #[test]
    fn it_can_run_not() {
        assert_interpret("!nil", "true");
    }

    #[test]
    fn it_can_eval_not_nil() {
        assert_interpret("!nil", "true");
    }

    #[test]
    fn it_can_eval_equality() {
        assert_interpret("5 == 5", "true");
        assert_interpret("5 == 4", "false");
        assert_interpret("5 == nil", "false");
        assert_interpret("nil == nil", "true");
        assert_interpret("true == false", "false");
        assert_interpret("true == true", "true");
        assert_interpret("false == false", "true");
    }

    #[test]
    fn it_can_compare_values() {
        assert_interpret("5 > 4", "true");
        assert_interpret("5 >= 5", "true");
        assert_interpret("4 < 5", "true");
        assert_interpret("5 <= 5", "true");
    }

    #[test]
    fn it_can_eval_logical_expressions() {
        assert_interpret("!(5 - 4 > 3 * 2 == !nil)", "true");
    }

    #[test]
    fn it_can_eval_strings() {
        let vm = assert_interpret(r#""Hello, World""#, "Hello, World");
        assert_eq!("Hello, World", vm.interner.borrow().lookup(0));
    }

    #[test]
    fn it_can_compare_strings() {
        assert_interpret(r#""string" == "string""#, "true");
        assert_interpret(r#""string" != "string""#, "false");
        assert_interpret(r#""string" != "another string""#, "true");
        assert_interpret(r#""string" == "another string""#, "false");
    }

    #[test]
    fn it_can_append_strings() {
        let vm = assert_interpret(r#""st" + "ri" + "ng""#, "string");
        assert_eq!("st", vm.interner.borrow().lookup(0));
        assert_eq!("ri", vm.interner.borrow().lookup(1));
        assert_eq!("ng", vm.interner.borrow().lookup(2));
        assert_eq!("stri", vm.interner.borrow().lookup(3));
        assert_eq!("string", vm.interner.borrow().lookup(4));
    }
}
