use crate::lox::chunk::OpCode;
use crate::lox::vm::VM;

pub mod lox;

fn main() {
    let mut vm = VM::new();

    let mut constant = vm.add_constant(1.2);
    vm.write_chunk(OpCode::Constant(constant), 123);

    constant = vm.add_constant(3.4);
    vm.write_chunk(OpCode::Constant(constant), 123);

    vm.write_chunk(OpCode::Add, 123);

    constant = vm.add_constant(5.6);
    vm.write_chunk(OpCode::Constant(constant), 123);

    vm.write_chunk(OpCode::Divide, 123);
    vm.write_chunk(OpCode::Negate, 123);

    vm.write_chunk(OpCode::Return, 123);

    match vm.run() {
        Ok(r) => println!("{}", r),
        Err(err) => {
            eprintln!("Error: {:?}", err);
            std::process::exit(-1);
        }
    }
}
