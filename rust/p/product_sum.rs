struct Parser<'a> { tokens: &'a [i64], cursor: usize, valid: bool }
impl Parser<'_> {
    fn list(&mut self, depth: i64, nested: bool) -> i64 {
        if depth > 16 { self.valid = false; return 0; }
        let mut sum = 0;
        while self.cursor < self.tokens.len() {
            let token = self.tokens[self.cursor]; self.cursor += 1;
            if token == 2002 { if !nested { self.valid = false; } return sum * depth; }
            if token == 2001 { sum += self.list(depth + 1, true); }
            else if (-1000..=1000).contains(&token) { sum += token; }
            else { self.valid = false; return 0; }
            if !self.valid { return 0; }
        }
        if nested { self.valid = false; } sum * depth
    }
}
#[no_mangle]
pub unsafe extern "C" fn product_sum(v: *const i64, n: usize) -> i64 {
    if v.is_null() || n < 1 || n > 129 { return -1; }
    let a = std::slice::from_raw_parts(v, n);
    if !(0..=128).contains(&a[0]) || n != a[0] as usize + 1 { return -1; }
    let mut p = Parser { tokens: &a[1..], cursor: 0, valid: true };
    let result = p.list(1, false);
    if p.valid && p.cursor == p.tokens.len() { result } else { -1 }
}
