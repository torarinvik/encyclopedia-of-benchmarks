/// 1 when the inputs differ; otherwise 0.
export fn xor_gate(left: u64, right: u64) i64 {
    return @intCast(left ^ right);
}
