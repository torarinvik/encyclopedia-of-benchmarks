/// 1 when either input is 1; otherwise 0.
export fn or_gate(left: u64, right: u64) i64 {
    return @intCast(left | right);
}
