module xor_gate

// 1 when the inputs differ; otherwise 0.
@[export: 'xor_gate']
pub fn xor_gate(left u64, right u64) i64 {
    return i64(left ^ right)
}
