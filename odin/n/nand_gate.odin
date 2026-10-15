package nand_gate

// 1 only when at least one input is 0; 0 when both are 1.
@(export)
nand_gate :: proc "c" (left, right: u64) -> i64 {
    return i64(1 - (left & right))
}
