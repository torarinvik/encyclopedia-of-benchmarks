module or_gate

// 1 when either input is 1; otherwise 0.
@[export: 'or_gate']
pub fn or_gate(left u64, right u64) i64 {
    return i64(left | right)
}
