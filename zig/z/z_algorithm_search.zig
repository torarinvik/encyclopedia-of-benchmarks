/// Case-insensitive ASCII pattern search using the Z algorithm.
export fn z_algorithm_search(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    const max_sequence_length = 2047;
    const max_concat_length = 4095;
    if (length < 2) return -1;
    if (values[0] < 0 or values[0] > max_sequence_length or
        values[1] < 0 or values[1] > max_sequence_length) return -1;
    const text_length: usize = @intCast(values[0]);
    const pattern_length: usize = @intCast(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (2..length) |i| if (values[i] < 0 or values[i] > 127) return -1;
    if (pattern_length == 0) {
        const count = text_length + 1;
        if (output_capacity < 4 * count) return -2;
        for (0..count) |i| {
            const position: u32 = @intCast(i + 1);
            for (0..4) |b| output[4 * i + b] = @intCast((position >> @intCast(8 * b)) & 0xff);
        }
        return @intCast(count);
    }
    var sequence: [max_concat_length]u32 = undefined;
    var z: [max_concat_length]usize = undefined;
    const total = pattern_length + 1 + text_length;
    for (0..pattern_length) |i| {
        var value: u32 = @intCast(values[2 + text_length + i]);
        if (value >= 'A' and value <= 'Z') value += 32;
        sequence[i] = value;
        z[i] = 0;
    }
    sequence[pattern_length] = 256;
    z[pattern_length] = 0;
    for (0..text_length) |i| {
        var value: u32 = @intCast(values[2 + i]);
        if (value >= 'A' and value <= 'Z') value += 32;
        sequence[pattern_length + 1 + i] = value;
        z[pattern_length + 1 + i] = 0;
    }
    var left: usize = 0;
    var right: usize = 0;
    for (1..total) |i| {
        if (i < right) z[i] = @min(z[i - left], right - i);
        while (i + z[i] < total and sequence[z[i]] == sequence[i + z[i]]) z[i] += 1;
        if (i + z[i] > right) { left = i; right = i + z[i]; }
    }
    var count: usize = 0;
    for (pattern_length + 1..total) |i| if (z[i] >= pattern_length) { count += 1; };
    if (output_capacity < 4 * count) return -2;
    var write: usize = 0;
    for (pattern_length + 1..total) |i| if (z[i] >= pattern_length) {
        const position: u32 = @intCast(i - pattern_length);
        for (0..4) |b| output[4 * write + b] = @intCast((position >> @intCast(8 * b)) & 0xff);
        write += 1;
    };
    return @intCast(count);
}
