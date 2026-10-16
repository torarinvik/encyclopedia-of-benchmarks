package imply_gate

// Two-input Boolean implication over the benchmark's 0/1 domain.
@(export)
imply_gate :: proc "c" (left, right: u64) -> i64 {
    if left == 0 || right == 1 {
        return 1
    }
    return 0
}
