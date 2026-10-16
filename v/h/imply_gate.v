module imply_gate

// Two-input Boolean implication over the benchmark's 0/1 domain.
@[export: 'imply_gate']
pub fn imply_gate(left u64, right u64) i64 {
    return if left == 0 || right == 1 { 1 } else { 0 }
}
