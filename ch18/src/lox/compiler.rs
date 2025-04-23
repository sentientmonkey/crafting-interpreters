use crate::lox::chunk::{Chunk, OpCode};
use crate::lox::scanner::{Scanner, Token, TokenType};
use crate::lox::value::Value;

pub struct Parser {
    scanner: Scanner,
    previous: Option<Token>,
    current: Option<Token>,
    chunk: Chunk,
}

#[derive(Copy, Clone, Debug, PartialEq)]
#[repr(u8)]
enum Precedence {
    None,
    Assignment, // =
    Or,         // or
    And,        // and
    Equality,   // == !=
    Comparison, // < > <= >=
    Term,       // + -
    Factor,     // * /
    Unary,      // ! -
    Call,       // . ()
    Primary,
}

impl Precedence {
    pub fn value(&self) -> u8 {
        *self as _
    }

    pub fn from_value(value: u8) -> Precedence {
        match value {
            0 => Self::None,
            1 => Self::Assignment,
            2 => Self::Or,
            3 => Self::And,
            4 => Self::Equality,
            5 => Self::Comparison,
            6 => Self::Term,
            7 => Self::Factor,
            8 => Self::Unary,
            9 => Self::Call,
            10 => Self::Primary,
            _ => Self::None,
        }
    }

    pub fn add(&self, value: u8) -> Precedence {
        Self::from_value(self.value() + value)
    }
}

type ParseFn = fn(&mut Parser) -> Result<(), ParserError>;

#[derive(Copy, Clone)]
struct ParseRule {
    prefix: Option<ParseFn>,
    infix: Option<ParseFn>,
    precedence: Precedence,
}

impl ParseRule {
    fn new(prefix: Option<ParseFn>, infix: Option<ParseFn>, precedence: Precedence) -> Self {
        Self {
            prefix,
            infix,
            precedence,
        }
    }
}

pub fn compile(source: &str) -> Result<Chunk, ParserError> {
    let scanner = Scanner::new(source);
    let mut parser = Parser::new(scanner);

    parser.advance()?;
    parser.expression()?;
    parser.consume(TokenType::EOF, "Expect end of expression.")?;
    parser.end_complier();

    Ok(parser.chunk)
}

#[derive(Debug, Clone)]
pub struct ParserError {
    pub token: Option<Token>,
    pub message: String,
}

impl Parser {
    pub fn new(scanner: Scanner) -> Parser {
        Parser {
            scanner,
            previous: None,
            current: None,
            chunk: Chunk::new(),
        }
    }

    fn advance(&mut self) -> Result<(), ParserError> {
        self.previous = self.current.clone();
        loop {
            self.current = Some(self.scanner.scan_token());
            match self.current.clone().unwrap().token_type {
                TokenType::Error(e) => return Err(self.error_at_current(e.as_str())),
                _ => break,
            }
        }

        Ok(())
    }

    fn consume(&mut self, token_type: TokenType, message: &str) -> Result<(), ParserError> {
        if self.current.is_some() && self.current.clone().unwrap().token_type == token_type {
            self.advance()?;
            return Ok(());
        }

        Err(self.error_at_current(message))
    }

    fn grouping(&mut self) -> Result<(), ParserError> {
        self.expression()?;
        self.consume(TokenType::RightParen, "Expect ')' after expression.")
    }

    fn number(&mut self) -> Result<(), ParserError> {
        match self.previous.clone().unwrap().token_type {
            TokenType::Number(n) => self.emit_constant(Value::Number(n)),
            _ => return Err(self.error_at_current("Expected number.")),
        }
        Ok(())
    }

    fn unary(&mut self) -> Result<(), ParserError> {
        let operator_type = self.previous.clone().unwrap().token_type;

        // compile the operand.
        self.parse_precendence(Precedence::Unary)?;

        // emit the operator instruction
        match operator_type {
            TokenType::Bang => self.emit_byte(OpCode::Not),
            TokenType::Minus => self.emit_byte(OpCode::Negate),
            _ => {} // Unreachable.
        }

        Ok(())
    }

    fn binary(&mut self) -> Result<(), ParserError> {
        let operator_type = self.previous.clone().unwrap().token_type;
        let rule = self.get_rule(operator_type.clone());
        self.parse_precendence(rule.precedence.add(1))?;

        match operator_type {
            TokenType::BangEqual => self.emit_bytes(&[OpCode::Equal, OpCode::Not]),
            TokenType::EqualEqual => self.emit_byte(OpCode::Equal),
            TokenType::Greater => self.emit_byte(OpCode::Greater),
            TokenType::GreaterEqual => self.emit_bytes(&[OpCode::Less, OpCode::Not]),
            TokenType::Less => self.emit_byte(OpCode::Less),
            TokenType::LessEqual => self.emit_bytes(&[OpCode::Greater, OpCode::Not]),
            TokenType::Plus => self.emit_byte(OpCode::Add),
            TokenType::Minus => self.emit_byte(OpCode::Subtract),
            TokenType::Star => self.emit_byte(OpCode::Multiply),
            TokenType::Slash => self.emit_byte(OpCode::Divide),
            _ => {} // Unreachable.
        }

        Ok(())
    }

    fn literal(&mut self) -> Result<(), ParserError> {
        let operator_type = self.previous.clone().unwrap().token_type;
        match operator_type {
            TokenType::True => self.emit_byte(OpCode::True),
            TokenType::False => self.emit_byte(OpCode::False),
            TokenType::Nil => self.emit_byte(OpCode::Nil),
            _ => {} // Unreachable.
        }
        Ok(())
    }

    fn parse_precendence(&mut self, precedence: Precedence) -> Result<(), ParserError> {
        self.advance()?;

        let token_type = self.previous.clone().unwrap().token_type;
        let prefix_rule = self.get_rule(token_type).prefix;

        match prefix_rule {
            None => return Err(self.error("Expect expression.")),
            Some(r) => r(self)?,
        }

        while precedence.value()
            <= self
                .get_rule(self.current.clone().unwrap().token_type)
                .precedence
                .value()
        {
            self.advance()?;
            let infix_rule = self
                .get_rule(self.previous.clone().unwrap().token_type)
                .infix;
            infix_rule.unwrap()(self)?;
        }

        Ok(())
    }

    fn get_rule(&self, token_type: TokenType) -> ParseRule {
        match token_type {
            TokenType::LeftParen => ParseRule::new(Some(Self::grouping), None, Precedence::None),
            TokenType::RightParen => ParseRule::new(None, None, Precedence::None),
            TokenType::Minus => {
                ParseRule::new(Some(Self::unary), Some(Self::binary), Precedence::Term)
            }
            TokenType::Plus => ParseRule::new(None, Some(Self::binary), Precedence::Term),
            TokenType::Slash => ParseRule::new(None, Some(Self::binary), Precedence::Factor),
            TokenType::Star => ParseRule::new(None, Some(Self::binary), Precedence::Factor),
            TokenType::Bang => ParseRule::new(Some(Self::unary), None, Precedence::None),
            TokenType::BangEqual => ParseRule::new(None, Some(Self::binary), Precedence::Equality),
            TokenType::EqualEqual => {
                ParseRule::new(None, Some(Self::binary), Precedence::Comparison)
            }
            TokenType::Greater => ParseRule::new(None, Some(Self::binary), Precedence::Comparison),
            TokenType::GreaterEqual => {
                ParseRule::new(None, Some(Self::binary), Precedence::Comparison)
            }
            TokenType::Less => ParseRule::new(None, Some(Self::binary), Precedence::Comparison),
            TokenType::LessEqual => {
                ParseRule::new(None, Some(Self::binary), Precedence::Comparison)
            }
            TokenType::Number(_) => ParseRule::new(Some(Self::number), None, Precedence::None),
            TokenType::Nil => ParseRule::new(Some(Self::literal), None, Precedence::None),
            TokenType::True => ParseRule::new(Some(Self::literal), None, Precedence::None),
            TokenType::False => ParseRule::new(Some(Self::literal), None, Precedence::None),
            _ => ParseRule::new(None, None, Precedence::None),
        }
    }

    fn expression(&mut self) -> Result<(), ParserError> {
        self.parse_precendence(Precedence::Assignment)
    }

    fn emit_byte(&mut self, byte: OpCode) {
        self.chunk
            .write_chunk(byte, self.previous.clone().unwrap().line);
    }

    fn emit_bytes(&mut self, bytes: &[OpCode]) {
        for byte in bytes {
            self.emit_byte(*byte);
        }
    }

    fn emit_return(&mut self) {
        self.emit_byte(OpCode::Return);
    }

    fn end_complier(&mut self) {
        self.emit_return();
    }

    fn make_constant(&mut self, value: Value) -> OpCode {
        let constant = self.chunk.add_constant(value);
        OpCode::Constant(constant)
    }

    fn emit_constant(&mut self, value: Value) {
        let constant = self.make_constant(value);
        self.emit_byte(constant)
    }

    fn error_at_current(&self, message: &str) -> ParserError {
        ParserError {
            token: self.current.clone(),
            message: String::from(message),
        }
    }

    fn error(&self, message: &str) -> ParserError {
        ParserError {
            token: None,
            message: String::from(message),
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::lox::chunk::*;
    use crate::lox::compiler::*;
    use crate::lox::value::Value;
    use std::fmt::Debug;
    use std::iter::zip;

    fn assert_same<T: PartialEq + Debug>(xs: Vec<T>, ys: Vec<T>) {
        assert!(
            xs.len() == ys.len(),
            "Not same length: {}, {}",
            xs.len(),
            ys.len()
        );

        zip(xs, ys).for_each(|(x, y)| assert!(x == y, "Not same: {:?}, {:?}", x, y));
    }

    fn assert_compiles(
        source: &str,
        expected_instructions: Vec<Instruction>,
        expected_constants: Vec<Value>,
    ) {
        let result = compile(source);
        assert!(result.is_ok(), "is not ok: {:?}", result.err());

        let chunk = result.unwrap();
        assert_same(chunk.instructions, expected_instructions);
        assert_same(chunk.constants, expected_constants);
    }

    #[test]
    fn it_compiles_binary() {
        assert_compiles(
            "1 + 2",
            vec![
                Instruction::new(OpCode::Constant(0), 1),
                Instruction::new(OpCode::Constant(1), 1),
                Instruction::new(OpCode::Add, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![Value::Number(1.0), Value::Number(2.0)],
        );
    }

    #[test]
    fn it_compiles_with_precedence() {
        assert_compiles(
            "2 * 3 + 4",
            vec![
                Instruction::new(OpCode::Constant(0), 1),
                Instruction::new(OpCode::Constant(1), 1),
                Instruction::new(OpCode::Multiply, 1),
                Instruction::new(OpCode::Constant(2), 1),
                Instruction::new(OpCode::Add, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![Value::Number(2.0), Value::Number(3.0), Value::Number(4.0)],
        );
    }

    #[test]
    fn it_compiles_strange() {
        assert_compiles(
            "(-1 + 2) * 3 - -4",
            vec![
                Instruction::new(OpCode::Constant(0), 1),
                Instruction::new(OpCode::Negate, 1),
                Instruction::new(OpCode::Constant(1), 1),
                Instruction::new(OpCode::Add, 1),
                Instruction::new(OpCode::Constant(2), 1),
                Instruction::new(OpCode::Multiply, 1),
                Instruction::new(OpCode::Constant(3), 1),
                Instruction::new(OpCode::Negate, 1),
                Instruction::new(OpCode::Subtract, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![
                Value::Number(1.0),
                Value::Number(2.0),
                Value::Number(3.0),
                Value::Number(4.0),
            ],
        );
    }

    #[test]
    fn it_compiles_nil() {
        assert_compiles(
            "nil",
            vec![
                Instruction::new(OpCode::Nil, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![],
        );
    }

    #[test]
    fn it_compiles_false() {
        assert_compiles(
            "false",
            vec![
                Instruction::new(OpCode::False, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![],
        );
    }

    #[test]
    fn it_compiles_true() {
        assert_compiles(
            "true",
            vec![
                Instruction::new(OpCode::True, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![],
        );
    }

    #[test]
    fn it_compiles_not() {
        assert_compiles(
            "!true",
            vec![
                Instruction::new(OpCode::True, 1),
                Instruction::new(OpCode::Not, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![],
        );
    }

    #[test]
    fn it_compiles_comparsion_operators() {
        assert_compiles(
            "true != false",
            vec![
                Instruction::new(OpCode::True, 1),
                Instruction::new(OpCode::False, 1),
                Instruction::new(OpCode::Equal, 1),
                Instruction::new(OpCode::Not, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![],
        );

        assert_compiles(
            "true == false",
            vec![
                Instruction::new(OpCode::True, 1),
                Instruction::new(OpCode::False, 1),
                Instruction::new(OpCode::Equal, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![],
        );

        assert_compiles(
            "5 > 4",
            vec![
                Instruction::new(OpCode::Constant(0), 1),
                Instruction::new(OpCode::Constant(1), 1),
                Instruction::new(OpCode::Greater, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![Value::Number(5.0), Value::Number(4.0)],
        );

        assert_compiles(
            "5 >= 4",
            vec![
                Instruction::new(OpCode::Constant(0), 1),
                Instruction::new(OpCode::Constant(1), 1),
                Instruction::new(OpCode::Less, 1),
                Instruction::new(OpCode::Not, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![Value::Number(5.0), Value::Number(4.0)],
        );

        assert_compiles(
            "5 < 4",
            vec![
                Instruction::new(OpCode::Constant(0), 1),
                Instruction::new(OpCode::Constant(1), 1),
                Instruction::new(OpCode::Less, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![Value::Number(5.0), Value::Number(4.0)],
        );

        assert_compiles(
            "5 <= 4",
            vec![
                Instruction::new(OpCode::Constant(0), 1),
                Instruction::new(OpCode::Constant(1), 1),
                Instruction::new(OpCode::Greater, 1),
                Instruction::new(OpCode::Not, 1),
                Instruction::new(OpCode::Return, 1),
            ],
            vec![Value::Number(5.0), Value::Number(4.0)],
        );
    }
}
