module and_gate

// Two-input Boolean AND over the benchmark's 0/1 domain.
@[export: 'and_gate']
pub fn and_gate(left u64, right u64) i64 {
    return i64(left & right)
}
