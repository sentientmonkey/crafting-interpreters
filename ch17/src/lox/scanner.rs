pub struct Scanner {
    source: String,
    start: usize,
    current: usize,
    line: usize,
}

#[derive(Debug, Clone, PartialEq)]
pub enum TokenType {
    // Single-character tokens.
    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    Comma,
    Dot,
    Minus,
    Plus,
    Semicolon,
    Slash,
    Star,
    // One or two character tokens.
    Bang,
    BangEqual,
    Equal,
    EqualEqual,
    Greater,
    GreaterEqual,
    Less,
    LessEqual,
    // Literals.
    Identifier(String),
    String(String),
    Number(f64),
    // Keywords.
    And,
    Class,
    Else,
    False,
    For,
    Fun,
    If,
    Nil,
    Or,
    Print,
    Return,
    Super,
    This,
    True,
    Var,
    While,

    Error(String),
    EOF,
}

#[derive(Debug, Clone)]
pub struct Token {
    pub token_type: TokenType,
    pub line: usize,
}

fn is_digit(c: char) -> bool {
    c >= '0' && c <= '9'
}

fn is_alpha(c: char) -> bool {
    (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}
impl Iterator for Scanner {
    type Item = Token;

    fn next(&mut self) -> Option<Self::Item> {
        if self.is_at_end() {
            None
        } else {
            let token = self.scan_token();
            Some(token)
        }
    }
}

impl Scanner {
    pub fn new(source: &str) -> Scanner {
        Scanner {
            source: String::from(source),
            start: 0,
            current: 0,
            line: 1,
        }
    }

    pub fn scan_token(&mut self) -> Token {
        self.skip_whitespace();
        self.start = self.current;

        if self.is_at_end() {
            return self.make_token(TokenType::EOF);
        }

        let c = self.advance();

        match c {
            c if is_alpha(c) => self.identifier(),
            c if is_digit(c) => self.number(),
            '(' => self.make_token(TokenType::LeftParen),
            ')' => self.make_token(TokenType::RightParen),
            '{' => self.make_token(TokenType::LeftBrace),
            '}' => self.make_token(TokenType::RightBrace),
            ';' => self.make_token(TokenType::Semicolon),
            ',' => self.make_token(TokenType::Comma),
            '.' => self.make_token(TokenType::Dot),
            '-' => self.make_token(TokenType::Minus),
            '+' => self.make_token(TokenType::Plus),
            '/' => self.make_token(TokenType::Slash),
            '*' => self.make_token(TokenType::Star),
            '!' if self.match_token('=') => self.make_token(TokenType::BangEqual),
            '!' => return self.make_token(TokenType::Bang),
            '=' if self.match_token('=') => self.make_token(TokenType::EqualEqual),
            '=' => return self.make_token(TokenType::Equal),
            '<' if self.match_token('=') => self.make_token(TokenType::LessEqual),
            '<' => return self.make_token(TokenType::Less),
            '>' if self.match_token('=') => self.make_token(TokenType::GreaterEqual),
            '>' => self.make_token(TokenType::Greater),
            '"' => self.string(),
            _ => self.error_token("Unexpected character."),
        }
    }

    fn is_at_end(&self) -> bool {
        self.current == self.source.len()
    }

    fn advance(&mut self) -> char {
        let c = self.source.chars().nth(self.current).unwrap();
        self.current += 1;
        c
    }

    fn peek(&self) -> Option<char> {
        self.source.chars().nth(self.current)
    }

    fn peek_next(&self) -> Option<char> {
        if self.is_at_end() {
            return None;
        }

        self.source.chars().nth(self.current + 1)
    }
    fn match_token(&mut self, expected: char) -> bool {
        if self.is_at_end() {
            return false;
        }
        if self.source.chars().nth(self.current).unwrap() != expected {
            return false;
        }

        self.current = self.current + 1;

        true
    }

    fn make_token(&self, token_type: TokenType) -> Token {
        Token {
            token_type,
            line: self.line,
        }
    }

    fn make_string(&self) -> Token {
        let s = String::from(&self.source[self.start + 1..self.current - 1]);
        self.make_token(TokenType::String(s))
    }

    fn make_identifier_type(&self) -> TokenType {
        let i = String::from(&self.source[self.start..self.current]);
        TokenType::Identifier(i)
    }

    fn make_number(&self) -> Token {
        let n = self.source[self.start..self.current]
            .parse::<f64>()
            .unwrap();

        self.make_token(TokenType::Number(n))
    }

    fn error_token(&self, message: &str) -> Token {
        self.make_token(TokenType::Error(String::from(message)))
    }

    fn skip_whitespace(&mut self) {
        loop {
            match self.peek() {
                Some(' ') | Some('\r') | Some('\t') => {
                    self.advance();
                }
                Some('\n') => {
                    self.line += 1;
                    self.advance();
                }
                Some('/') => {
                    if self.peek_next() == Some('/') {
                        while self.peek() != Some('\n') && !self.is_at_end() {
                            self.advance();
                        }
                    } else {
                        return;
                    }
                }
                _ => {
                    return;
                }
            }
        }
    }

    fn string(&mut self) -> Token {
        while self.peek() != Some('"') && !self.is_at_end() {
            if self.peek() == Some('\n') {
                self.line = self.line + 1;
            }
            self.advance();
        }

        if self.is_at_end() {
            return self.error_token("Unterminated string.");
        }

        self.advance();
        self.make_string()
    }

    fn number(&mut self) -> Token {
        while self.peek().map_or(false, is_digit) {
            self.advance();
        }

        if self.peek() == Some('.') && self.peek_next().map_or(false, is_digit) {
            self.advance();

            while self.peek().map_or(false, is_digit) {
                self.advance();
            }
        }

        self.make_number()
    }

    fn check_keyword(
        &self,
        start: usize,
        length: usize,
        rest: &str,
        token_type: TokenType,
    ) -> TokenType {
        let substr = &self.source[self.start + start..self.start + start + length];

        if substr == rest {
            token_type
        } else {
            self.make_identifier_type()
        }
    }

    fn identifier_type(&self) -> TokenType {
        match self.source.chars().nth(self.start).unwrap() {
            'a' => self.check_keyword(1, 2, "nd", TokenType::And),
            'c' => self.check_keyword(1, 4, "lass", TokenType::Class),
            'e' => self.check_keyword(1, 3, "lse", TokenType::Else),
            'f' if self.current - self.start > 1 => {
                match self.source.chars().nth(self.start + 1).unwrap() {
                    'a' => self.check_keyword(2, 3, "lse", TokenType::False),
                    'o' => self.check_keyword(2, 1, "r", TokenType::For),
                    'u' => self.check_keyword(2, 1, "n", TokenType::Fun),
                    _ => self.make_identifier_type(),
                }
            }
            'i' => self.check_keyword(1, 1, "f", TokenType::If),
            'n' => self.check_keyword(1, 2, "il", TokenType::Nil),
            'o' => self.check_keyword(1, 1, "r", TokenType::Or),
            'p' => self.check_keyword(1, 4, "rint", TokenType::Print),
            'r' => self.check_keyword(1, 5, "eturn", TokenType::Return),
            's' => self.check_keyword(1, 4, "uper", TokenType::Super),
            't' if self.current - self.start > 1 => {
                match self.source.chars().nth(self.start + 1).unwrap() {
                    'h' => self.check_keyword(2, 2, "is", TokenType::This),
                    'r' => self.check_keyword(2, 2, "ue", TokenType::This),
                    _ => self.make_identifier_type(),
                }
            }
            'v' => self.check_keyword(1, 2, "ar", TokenType::Var),
            'w' => self.check_keyword(1, 4, "hile", TokenType::While),
            _ => self.make_identifier_type(),
        }
    }
    fn identifier(&mut self) -> Token {
        while self.peek().map_or(false, is_alpha) || self.peek().map_or(false, is_digit) {
            self.advance();
        }

        self.make_token(self.identifier_type())
    }
}

#[cfg(test)]
mod tests {
    use crate::lox::scanner::*;

    fn assert_next_token(scanner: &mut Scanner, token_type: TokenType) {
        let token = scanner.scan_token();
        assert_eq!(token.token_type, token_type, "token: {:?}", token);
    }

    fn assert_token(source: &str, token_type: TokenType) {
        let mut scanner = Scanner::new(source);
        assert_next_token(&mut scanner, token_type);
    }

    #[test]
    fn it_scans_eof() {
        let mut scanner = Scanner::new("");
        assert_next_token(&mut scanner, TokenType::EOF);
    }

    #[test]
    fn it_scans_single_character_tokens() {
        let mut scanner = Scanner::new("(){},.+;*");

        assert_next_token(&mut scanner, TokenType::LeftParen);
        assert_next_token(&mut scanner, TokenType::RightParen);
        assert_next_token(&mut scanner, TokenType::LeftBrace);
        assert_next_token(&mut scanner, TokenType::RightBrace);
        assert_next_token(&mut scanner, TokenType::Comma);
        assert_next_token(&mut scanner, TokenType::Dot);
        assert_next_token(&mut scanner, TokenType::Plus);
        assert_next_token(&mut scanner, TokenType::Semicolon);
        assert_next_token(&mut scanner, TokenType::Star);
        assert_next_token(&mut scanner, TokenType::EOF);
    }

    #[test]
    fn it_scans_one_or_two_character_tokens() {
        let mut scanner = Scanner::new("!!====<<=>>=");

        assert_next_token(&mut scanner, TokenType::Bang);
        assert_next_token(&mut scanner, TokenType::BangEqual);
        assert_next_token(&mut scanner, TokenType::EqualEqual);
        assert_next_token(&mut scanner, TokenType::Equal);
        assert_next_token(&mut scanner, TokenType::Less);
        assert_next_token(&mut scanner, TokenType::LessEqual);
        assert_next_token(&mut scanner, TokenType::Greater);
        assert_next_token(&mut scanner, TokenType::GreaterEqual);
        assert_next_token(&mut scanner, TokenType::EOF);
    }

    #[test]
    fn it_skips_whitespace() {
        let mut scanner = Scanner::new("      ");
        assert_next_token(&mut scanner, TokenType::EOF);
    }

    #[test]
    fn it_can_scan_slash() {
        let mut scanner = Scanner::new("/");

        assert_next_token(&mut scanner, TokenType::Slash);
        assert_next_token(&mut scanner, TokenType::EOF);
    }

    #[test]
    fn it_can_scan_comments() {
        let mut scanner = Scanner::new("// this is a comment");

        assert_next_token(&mut scanner, TokenType::EOF);
    }

    #[test]
    fn it_can_scan_strings() {
        let mut scanner = Scanner::new("\"I am a string\"");

        let token = scanner.scan_token();

        assert_eq!(
            token.token_type,
            TokenType::String(String::from("I am a string"))
        );

        assert_next_token(&mut scanner, TokenType::EOF);
    }

    #[test]
    fn it_can_scan_ints() {
        let mut scanner = Scanner::new("1234");

        let token = scanner.scan_token();

        assert_eq!(token.token_type, TokenType::Number(1234.0));
    }

    #[test]
    fn it_can_scan_floats() {
        let mut scanner = Scanner::new("12.34");

        let token = scanner.scan_token();

        assert_eq!(token.token_type, TokenType::Number(12.34));
    }

    #[test]
    fn it_can_scan_identifiers() {
        let mut scanner = Scanner::new("foo_bar");

        let token = scanner.scan_token();

        assert_eq!(
            token.token_type,
            TokenType::Identifier(String::from("foo_bar"))
        );
    }

    #[test]
    fn it_can_scan_reserved_keywords() {
        assert_token("and", TokenType::And);
        assert_token("class", TokenType::Class);
        assert_token("else", TokenType::Else);
        assert_token("false", TokenType::False);
        assert_token("for", TokenType::For);
        assert_token("fun", TokenType::Fun);
        assert_token("if", TokenType::If);
        assert_token("nil", TokenType::Nil);
        assert_token("or", TokenType::Or);
        assert_token("print", TokenType::Print);
        assert_token("return", TokenType::Return);
        assert_token("super", TokenType::Super);
        assert_token("this", TokenType::This);
        assert_token("var", TokenType::Var);
        assert_token("while", TokenType::While);
    }

    #[test]
    fn it_can_scan_expression() {
        let mut scanner = Scanner::new("print 1 + 2;");

        assert_next_token(&mut scanner, TokenType::Print);
        assert_next_token(&mut scanner, TokenType::Number(1.0));
        assert_next_token(&mut scanner, TokenType::Plus);
        assert_next_token(&mut scanner, TokenType::Number(2.0));
        assert_next_token(&mut scanner, TokenType::Semicolon);
        assert_next_token(&mut scanner, TokenType::EOF);
    }
}
