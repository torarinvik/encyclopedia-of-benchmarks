fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> (8 * byte));
}

export fn simplest_radical_form(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length != 1) return -1;
    const original = values[0];
    if (original < 0 or original > 100000000) return -1;
    if (output == null or capacity < 16) return -2;

    var coefficient: i64 = 1;
    var root_term: i64 = 1;
    if (original == 0) {
        root_term = 0;
    } else {
        var remainder = original;
        var factor: i64 = 2;
        while (factor * factor <= original) : (factor += 1) {
            var count: i64 = 0;
            while (@rem(remainder, factor) == 0) {
                remainder = @divTrunc(remainder, factor);
                count += 1;
            }
            var power: i64 = 0;
            while (power < @divTrunc(count, 2)) : (power += 1) coefficient *= factor;
            if (@rem(count, 2) != 0) root_term *= factor;
        }
        root_term *= remainder;
    }
    putI64(output, 0, coefficient);
    putI64(output, 8, root_term);
    return 16;
}
