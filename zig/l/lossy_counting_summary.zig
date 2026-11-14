fn putWord(output: [*c]u8, offset: usize, value: i64) void {
    var bits: u64 = @bitCast(value);
    for (0..8) |j| { output[offset+j] = @truncate(bits); bits >>= 8; }
}

pub export fn lossy_counting_summary(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 66 or input[0] < 2 or input[0] > 16 or input[1] < 0 or input[1] > 64) return -1;
    const width: usize = @intCast(input[0]);
    const n: usize = @intCast(input[1]);
    if (length != 2+n) return -1;
    for (0..n) |i| { if (input[2+i] < 0 or input[2+i] > 15) return -1; }
    var count: [16]i64 = @splat(0);
    var error_count: [16]i64 = @splat(0);
    for (0..n) |i| {
        const item: usize = @intCast(input[2+i]);
        const bucket: i64 = @intCast(i/width+1);
        if (count[item] == 0) error_count[item] = bucket-1;
        count[item] += 1;
        if ((i+1)%width == 0) {
            for (0..16) |j| {
                if (count[j] != 0 and count[j]+error_count[j] <= bucket) { count[j] = 0; error_count[j] = 0; }
            }
        }
    }
    var active: usize = 0;
    for (count) |value| { if (value != 0) active += 1; }
    const bytes = 8+24*active;
    if (output == null or capacity < bytes) return -2;
    putWord(output, 0, @intCast(active));
    var offset: usize = 8;
    for (0..16) |i| {
        if (count[i] != 0) {
            putWord(output, offset, @intCast(i));
            putWord(output, offset+8, count[i]);
            putWord(output, offset+16, error_count[i]);
            offset += 24;
        }
    }
    return @intCast(bytes);
}
