use crate::lox::chunk::{Chunk, OpCode};
use std::fmt::Write;

pub type Value = f64;

pub struct VM {
    chunks: Vec<Chunk>,
    values: Vec<Value>,
}

impl VM {
    pub fn new() -> VM {
        VM {
            chunks: vec![],
            values: vec![],
        }
    }

    pub fn add_constant(&mut self, value: f64) -> usize {
        let constant = self.values.len();
        self.values.push(value);
        constant
    }

    pub fn write_chunk(&mut self, chunk: Chunk) {
        self.chunks.push(chunk);
    }

    pub fn disassemble(&self, name: &str) -> Result<String, std::fmt::Error> {
        let mut output = String::from("");
        writeln!(output, "== {} ==", name)?;
        for (offset, chunk) in self.chunks.iter().enumerate() {
            write!(output, "{:04} ", offset)?;
            if offset > 0 && chunk.line == self.chunks.get(offset - 1).unwrap().line {
                write!(output, "   | ")?;
            } else {
                write!(output, "{:4} ", chunk.line)?;
            }

            output.push_str(self.disassemble_chunk(chunk)?.as_str());
        }
        Ok(output)
    }

    fn disassemble_chunk(&self, chunk: &Chunk) -> Result<String, std::fmt::Error> {
        Ok(match chunk.code {
            OpCode::Constant(c) => self.constant_instruction("OP_CONSTANT", c),
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

#[cfg(test)]
mod tests {
    use crate::lox::vm::VM;
    use crate::lox::vm::{Chunk, OpCode};

    #[test]
    fn it_dissasembles() {
        let expected = "== test chunk ==\n\
                        0000  123 OP_CONSTANT         0 '1.2\n\
                        0001    | OP_RETURN\n";

        let mut vm = VM::new();

        let constant = vm.add_constant(1.2);
        vm.write_chunk(Chunk::new(OpCode::Constant(constant), 123));
        vm.write_chunk(Chunk::new(OpCode::Return, 123));

        let actual = vm.disassemble("test chunk").expect("Could not write");
        assert_eq!(expected, actual);
    }
}
