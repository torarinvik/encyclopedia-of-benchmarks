fn putWord(out: [*c]u8, offset: usize, value: i64) void {
    var bits: u64 = @bitCast(value);
    for (0..8) |j| { out[offset+j] = @truncate(bits); bits >>= 8; }
}

pub export fn sticky_sampling_summary(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 323 or input[0] < 1 or input[0] > 8 or
        input[1] < 0 or input[1] > 64 or input[2] < 0 or input[2] > 256) return -1;
    const t: usize = @intCast(input[0]);
    const n: usize = @intCast(input[1]);
    const k: usize = @intCast(input[2]);
    if (length != 3+n+k) return -1;
    for (0..n) |i| { if (input[3+i] < 0 or input[3+i] > 15) return -1; }
    for (0..k) |i| { if (input[3+n+i] < 0 or input[3+n+i] > 255) return -1; }
    var counts: [16]i64 = @splat(0);
    var cursor: usize = 0;
    var rate: usize = 1;
    var end: usize = 2*t;
    for (0..n) |i| {
        if (i == end) {
            rate *= 2; end += rate*t;
            for (&counts) |*count| {
                while (count.* != 0) {
                    if (cursor == k) return -1;
                    const draw = input[3+n+cursor]; cursor += 1;
                    if (@mod(draw, 2) == 1) break;
                    count.* -= 1;
                }
            }
        }
        const item: usize = @intCast(input[3+i]);
        if (counts[item] != 0) counts[item] += 1 else {
            if (cursor == k) return -1;
            const draw: usize = @intCast(input[3+n+cursor]); cursor += 1;
            if (draw % rate == 0) counts[item] = 1;
        }
    }
    if (cursor != k) return -1;
    var active: usize = 0;
    for (counts) |count| { if (count != 0) active += 1; }
    const bytes = 8+16*active;
    if (output == null or capacity < bytes) return -2;
    putWord(output, 0, @intCast(active));
    var offset: usize = 8;
    for (counts, 0..) |count, item| {
        if (count != 0) { putWord(output, offset, @intCast(item)); putWord(output, offset+8, count); offset += 16; }
    }
    return @intCast(bytes);
}
