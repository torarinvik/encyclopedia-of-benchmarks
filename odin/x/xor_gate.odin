package xor_gate

// 1 when the inputs differ; otherwise 0.
@(export)
xor_gate :: proc "c" (left, right: u64) -> i64 {
    return i64(left ^ right)
}
