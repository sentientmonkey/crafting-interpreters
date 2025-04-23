use crate::lox::value::Value;
use std::fmt::Write;

#[derive(Debug, Copy, Clone, PartialEq)]
pub enum OpCode {
    Constant(usize),
    Add,
    Subtract,
    Multiply,
    Divide,
    Negate,
    Return,
}

#[derive(Debug, Copy, Clone, PartialEq)]
pub struct Instruction {
    pub code: OpCode,
    pub line: usize,
}

impl Instruction {
    pub fn new(code: OpCode, line: usize) -> Instruction {
        Instruction { code, line }
    }
}

pub struct Chunk {
    pub instructions: Vec<Instruction>,
    pub constants: Vec<Value>,
}

impl Chunk {
    pub fn new() -> Chunk {
        Chunk {
            instructions: vec![],
            constants: vec![],
        }
    }

    pub fn add_constant(&mut self, value: Value) -> usize {
        let constant = self.constants.len();
        self.constants.push(value);
        constant
    }

    pub fn write_chunk(&mut self, code: OpCode, line: usize) {
        self.instructions.push(Instruction::new(code, line));
    }

    pub fn disassemble(&self, name: &str) -> Result<String, std::fmt::Error> {
        let mut output = String::from("");
        writeln!(output, "== {} ==", name)?;
        for (offset, instruction) in self.instructions.iter().enumerate() {
            write!(
                output,
                "{}",
                self.disassemble_instruction(instruction, offset)?
            )?;
        }
        Ok(output)
    }

    pub fn disassemble_instruction(
        &self,
        instruction: &Instruction,
        offset: usize,
    ) -> Result<String, std::fmt::Error> {
        let mut output = String::new();
        write!(output, "{:04} ", offset)?;

        if offset > 0 && instruction.line == self.instructions.get(offset - 1).unwrap().line {
            write!(output, "   | ")?;
        } else {
            write!(output, "{:4} ", instruction.line)?;
        }

        output.push_str(self.disassemble_chunk(instruction)?.as_str());

        Ok(output)
    }

    fn disassemble_chunk(&self, instruction: &Instruction) -> Result<String, std::fmt::Error> {
        Ok(match instruction.code {
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
        writeln!(output, "{}", self.constants.get(constant).unwrap())?;
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
    use crate::lox::chunk::Chunk;
    use crate::lox::chunk::OpCode;

    #[test]
    fn it_dissasembles() {
        let expected = "== test chunk ==\n\
                        0000  123 OP_CONSTANT         0 '1.2\n\
                        0001    | OP_RETURN\n";

        let mut chunk = Chunk::new();

        let constant = chunk.add_constant(1.2);
        chunk.write_chunk(OpCode::Constant(constant), 123);
        chunk.write_chunk(OpCode::Return, 123);

        let actual = chunk.disassemble("test chunk").expect("Could not write");
        assert_eq!(expected, actual);
    }
}
