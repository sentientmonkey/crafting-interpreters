#[derive(Debug, Copy, Clone)]
pub enum OpCode {
  Constant(usize),
  Return,
}

pub struct Chunk {
    pub code: OpCode,
    pub line: usize,
}

impl Chunk {
    pub fn new(code: OpCode, line: usize) -> Chunk {
        Chunk {
            code,
            line,
        }
    }
}
