/// 1 when the inputs are equal; otherwise 0.
export fn xnor_gate(left: u64, right: u64) i64 {
    return @intCast(1 - (left ^ right));
}
