/// Two-input Boolean AND over the benchmark's 0/1 domain.
export fn and_gate(left: u64, right: u64) i64 {
    return @intCast(left & right);
}
