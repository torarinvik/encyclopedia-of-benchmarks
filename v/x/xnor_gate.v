module xnor_gate

// 1 when the inputs are equal; otherwise 0.
@[export: 'xnor_gate']
pub fn xnor_gate(left u64, right u64) i64 {
    return i64(1 - (left ^ right))
}
