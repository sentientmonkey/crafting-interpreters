use std::hash::{BuildHasherDefault, Hasher};

pub struct FnvHasher(u64);

// using https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function#FNV_hash_parameters
impl Default for FnvHasher {
    fn default() -> Self {
        Self(0xcbf29ce484222325)
    }
}

impl Hasher for FnvHasher {
    fn finish(&self) -> u64 {
        self.0
    }

    fn write(&mut self, bytes: &[u8]) {
        let Self(mut hash) = *self;

        for byte in bytes.iter() {
            hash ^= *byte as u64;
            hash = hash.wrapping_mul(0x100000001b3);
        }

        *self = Self(hash);
    }
}

pub type FnvBuildHasher = BuildHasherDefault<FnvHasher>;

#[cfg(test)]
mod tests {
    use super::*;

    fn hash_string(s: &str) -> u64 {
        let mut hasher = FnvHasher::default();
        hasher.write(s.as_bytes());
        hasher.finish()
    }

    #[test]
    fn it_can_hash_string() {
        let mut id = hash_string("hello");
        assert_eq!(0xa430d84680aabd0b, id);
        id = hash_string(&"hello world");
        assert_eq!(0x779a65e7023cd2e7, id);
    }
}
