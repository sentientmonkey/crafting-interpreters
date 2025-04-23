use crate::lox::chunk::{Chunk, OpCode};
use crate::lox::vm::VM;

pub mod lox;

fn main() {
    let mut vm = VM::new();

    let constant = vm.add_constant(1.2);
    vm.write_chunk(Chunk::new(OpCode::Constant(constant), 123));
    vm.write_chunk(Chunk::new(OpCode::Return, 123));

    print!("{}", vm.disassemble("test chunk").expect("Could not write"));
}
