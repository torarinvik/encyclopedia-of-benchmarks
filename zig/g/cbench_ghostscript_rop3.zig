// Independent bounded ROP3 profile; full AFPL v5 terms are in the package.
export fn cbench_ghostscript_rop3(values: [*c]const i64, length: usize) i64 {
    if (length > 5 or (length != 0 and values == null) or length != 4) return -1;
    for (0..3) |i| if (values[i] < 0 or values[i] > 4294967295) return -1;
    if (values[3] < 0 or values[3] > 255) return -1;
    const d: u64 = @intCast(values[0]);
    const s: u64 = @intCast(values[1]);
    const t: u64 = @intCast(values[2]);
    const code: u64 = @intCast(values[3]);
    var result: u64 = 0;
    for (0..32) |bit| {
        const index = (((t >> @intCast(bit)) & 1) << 2) |
            (((s >> @intCast(bit)) & 1) << 1) | ((d >> @intCast(bit)) & 1);
        if (((code >> @intCast(index)) & 1) != 0) result |= @as(u64, 1) << @intCast(bit);
    }
    return @intCast(result);
}
