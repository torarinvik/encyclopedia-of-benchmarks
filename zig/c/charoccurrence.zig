const MAX_INPUT: usize = 128;
const MAX_OUTPUT: usize = 1024;

fn appendDecimal(buffer: []u8, start: usize, value: usize) usize {
    var digits: [3]u8 = @splat(0);
    var count: usize = 0;
    var remaining = value;
    while (true) {
        digits[count] = '0' + @as(u8, @intCast(remaining % 10));
        count += 1;
        remaining /= 10;
        if (remaining == 0) break;
    }
    var offset = start;
    while (count > 0) {
        count -= 1;
        buffer[offset] = digits[count];
        offset += 1;
    }
    return offset;
}

export fn charoccurrence(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (length > MAX_INPUT or (length > 0 and values == null)) return -1;
    var counts: [128]usize = @splat(0);
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 127) return -1;
        counts[@intCast(value)] += 1;
    }

    var encoded: [MAX_OUTPUT]u8 = @splat(0);
    var used: usize = 0;
    for (0..128) |codepoint| {
        const count = counts[codepoint];
        if (count == 0) continue;
        if (used > 0) {
            encoded[used] = ',';
            used += 1;
        }
        used = appendDecimal(encoded[0..], used, codepoint);
        encoded[used] = '=';
        used += 1;
        used = appendDecimal(encoded[0..], used, count);
    }
    if (used > capacity or (used > 0 and output == null)) return -2;
    for (0..used) |index| output[index] = encoded[index];
    return @intCast(used);
}
