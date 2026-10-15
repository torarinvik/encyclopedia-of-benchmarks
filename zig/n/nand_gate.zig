/// 1 only when at least one input is 0; 0 when both are 1.
export fn nand_gate(left: u64, right: u64) i64 {
    return @intCast(1 - (left & right));
}
