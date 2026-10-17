fn isRemoved(value: i64, values: []const i64, n: usize, by: usize) bool {
    if (by == 0) return true;
    const suffix_start = n - by;
    for (values[2 + suffix_start .. 2 + n]) |key| {
        if (value == key) return true;
    }
    return false;
}

fn putI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn shorten_vector(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const max_input_length: usize = 67;
    if (input == null or length < 2 or length > max_input_length) return -1;
    const values = input.?[0..length];
    const raw_n = values[0];
    const raw_by = values[1];
    if (raw_n < 0 or raw_n > 64 or raw_by < 0 or raw_by > raw_n) return -1;
    const n: usize = @intCast(raw_n);
    const by: usize = @intCast(raw_by);
    if (length != 2 + n) return -1;
    for (values[2..]) |value| {
        if (value < -1_000_000 or value > 1_000_000) return -1;
    }

    var survivor_count: usize = 0;
    for (0..n) |i| {
        if (!isRemoved(values[2 + i], values, n, by)) survivor_count += 1;
    }
    const bytes = survivor_count * 8;
    if (output == null or capacity < bytes) return -2;

    const result = output.?[0..bytes];
    var written: usize = 0;
    for (0..n) |i| {
        const value = values[2 + i];
        if (!isRemoved(value, values, n, by)) {
            putI64Le(result, written * 8, value);
            written += 1;
        }
    }
    return @intCast(bytes);
}
