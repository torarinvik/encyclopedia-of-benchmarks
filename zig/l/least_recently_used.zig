fn put_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits = @as(u64, @bitCast(value));
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn least_recently_used(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 66) return -1;
    const capacity_value = input[0];
    const reference_count_value = input[1];
    if (capacity_value < 1 or capacity_value > 16 or reference_count_value < 0 or reference_count_value > 64) return -1;
    const cache_capacity: usize = @intCast(capacity_value);
    const references: usize = @intCast(reference_count_value);
    if (length != 2 + references) return -1;
    for (0..references) |i| {
        const key = input[2 + i];
        if (key < -2147483648 or key > 2147483647) return -1;
    }

    var keys: [16]i64 = @splat(0);
    var count: usize = 0;
    for (0..references) |i| {
        const key = input[2 + i];
        var found = count;
        for (0..count) |j| { if (keys[j] == key) { found = j; break; } }
        if (found < count) {
            var j = found;
            while (j + 1 < count) : (j += 1) keys[j] = keys[j + 1];
            count -= 1;
        } else if (count == cache_capacity) count -= 1;
        var j = count;
        while (j > 0) : (j -= 1) keys[j] = keys[j - 1];
        keys[0] = key;
        count += 1;
    }

    const elements = count + 1;
    const required = elements * 8;
    if (output == null or output_capacity < required) return -2;
    const out: [*]u8 = @ptrCast(output);
    put_i64_le(out, 0, @intCast(count));
    for (0..count) |i| put_i64_le(out, 8 * (i + 1), keys[i]);
    return @intCast(elements);
}
