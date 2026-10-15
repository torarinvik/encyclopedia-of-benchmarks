fn floorSqrt(value: i64) i64 {
    var low: i64 = 0;
    var high = value + 1;
    while (high - low > 1) {
        const middle = low + @divTrunc(high - low, 2);
        if (middle <= @divTrunc(value, middle)) low = middle else high = middle;
    }
    return low;
}

/// Encode the Juggler sequence through its first 1 as little-endian u32 values.
export fn juggler_sequence(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < 1 or value > 25) return -1;
    var sequence: [16]i64 = undefined;
    var count: usize = 1;
    sequence[0] = value;
    while (sequence[count - 1] != 1) {
        const current = sequence[count - 1];
        sequence[count] = if (@mod(current, 2) == 0) floorSqrt(current)
            else floorSqrt(current * current * current);
        count += 1;
    }
    const required = count * 4;
    if (output_capacity < required) return -2;
    for (0..count) |index| {
        const term: u32 = @intCast(sequence[index]);
        for (0..4) |byte| output[4 * index + byte] = @truncate(term >> @intCast(8 * byte));
    }
    return @intCast(required);
}
