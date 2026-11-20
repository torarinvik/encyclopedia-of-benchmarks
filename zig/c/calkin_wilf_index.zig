// Uncompiled indexed Calkin–Wilf fraction draft.
export fn calkin_wilf_index(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const ptr = input orelse return -1;
    if (length != 1) return -1;
    const raw = ptr[0];
    if (raw < 1 or raw >= (@as(i64,1) << 62)) return -1;
    const out_ptr = output orelse return -2;
    if (capacity < 16) return -2;
    const index: u64 = @intCast(raw);
    var high: u64 = 1;
    while (high <= index / 2) high *= 2;
    var numerator: u64 = 1;
    var denominator: u64 = 1;
    high /= 2;
    while (high != 0) {
        if ((index & high) != 0) { numerator += denominator; } else { denominator += numerator; }
        high /= 2;
    }
    for (0..8) |i| {
        out_ptr[i] = @truncate(numerator >> @intCast(8*i));
        out_ptr[i+8] = @truncate(denominator >> @intCast(8*i));
    }
    return 16;
}
