const MAX_NODES: usize = 128;
const MAX_OUTPUT: usize = 3589;
fn appendI64(buffer: *[MAX_OUTPUT]u8, start: usize, value: i64) usize {
    var digits: [20]u8 = undefined; var length: usize = 0;
    var magnitude: u64 = if (value < 0) @as(u64, @intCast(-(value + 1))) + 1 else @intCast(value);
    while (true) { digits[length] = @intCast('0' + magnitude % 10); length += 1; magnitude /= 10; if (magnitude == 0) break; }
    var p = start; buffer[p] = '<'; p += 1; if (value < 0) { buffer[p] = '-'; p += 1; }
    while (length > 0) { length -= 1; buffer[p] = digits[length]; p += 1; }
    buffer[p] = '>'; p += 1; @memcpy(buffer[p..][0..6], " ---> "); return p + 6;
}
export fn from_sequence(v: [*c]const i64, n: usize, out: [*c]u8, cap: usize) i64 {
    if (v == null or n < 2 or n > MAX_NODES + 1) return -1;
    const count = v[0]; if (count < 1 or count > 128 or n != @as(usize, @intCast(count)) + 1) return -1;
    var buffer: [MAX_OUTPUT]u8 = undefined; var p: usize = 0;
    for (0..@intCast(count)) |i| p = appendI64(&buffer, p, v[i + 1]);
    @memcpy(buffer[p..][0..5], "<END>"); p += 5;
    if (out == null or cap < p) return -2;
    @memcpy(out[0..p], buffer[0..p]); return @intCast(p);
}
