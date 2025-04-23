use crate::lox::interner::Symbol;
use std::convert::From;
use std::fmt;

#[derive(Debug, Clone, PartialEq)]
pub enum Value {
    Bool(bool),
    Nil,
    Number(f64),
    String(Symbol),
}

impl Value {
    pub fn is_number(&self) -> bool {
        match &self {
            Value::Number(_) => true,
            _ => false,
        }
    }

    pub fn as_number(&self) -> Result<f64, String> {
        match &self {
            Value::Number(n) => Ok(n.clone()),
            _ => Err(String::from("Operands must be numbers.")),
        }
    }

    pub fn is_string(&self) -> bool {
        match &self {
            Value::String(_) => true,
            _ => false,
        }
    }

    pub fn as_string(&self) -> Result<&Symbol, String> {
        match &self {
            Value::String(s) => Ok(s),
            _ => Err(String::from("Operands must be strings.")),
        }
    }

    pub fn is_falsey(&self) -> bool {
        match *self {
            Value::Nil => true,
            Value::Bool(false) => true,
            _ => false,
        }
    }
}

impl fmt::Display for Value {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match &self {
            Value::Bool(b) => write!(f, "{}", b),
            Value::Number(n) => write!(f, "{}", n),
            Value::Nil => write!(f, "nil"),
            Value::String(s) => write!(f, "{}", s),
        }
    }
}

impl From<f64> for Value {
    fn from(n: f64) -> Self {
        Self::Number(n)
    }
}

impl From<bool> for Value {
    fn from(b: bool) -> Self {
        Self::Bool(b)
    }
}
