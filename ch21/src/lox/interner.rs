use crate::lox::fnv::FnvBuildHasher;
use std::collections::HashMap;
use std::rc::Rc;

pub type Symbol = u32;

#[derive(Debug, Default)]
pub struct Interner {
    map: HashMap<Rc<String>, Symbol, FnvBuildHasher>,
    vec: Vec<Rc<String>>,
}

impl Interner {
    pub fn intern(&mut self, name: &str) -> Symbol {
        let s = name.to_string();
        match self.map.get(&s) {
            Some(id) => return *id,
            _ => {}
        }
        let id = self.vec.len() as Symbol;
        let owned = Rc::new(name.to_owned());
        self.map.insert(owned.clone(), id);
        self.vec.push(owned.clone());

        id
    }

    pub fn lookup(&self, idx: Symbol) -> &str {
        self.vec.get(idx as usize).unwrap().as_str()
    }
}
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_intern_strings() {
        let mut interner = Interner::default();

        let a = interner.intern("astring");
        assert_eq!(a, interner.intern("astring"));
        let b = interner.intern("anotherstring");
        assert_ne!(a, b);

        assert_eq!("astring", interner.lookup(a));
        assert_eq!("anotherstring", interner.lookup(b));
    }
}
