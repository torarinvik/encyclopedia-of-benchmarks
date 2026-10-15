const MAX_LIMIT: usize = 8_000;

fn writeU32Le(output: [*]u8, position: *usize, value: i64) void {
    const encoded: u32 = @intCast(value);
    for (0..4) |byte| {
        output[position.*] = @truncate(encoded >> @as(u5, @intCast(byte * 8)));
        position.* += 1;
    }
}

/// Enumerate amicable pairs below an exclusive upper limit using a divisor-sum sieve.
export fn amicable_pairs_below(values: [*c]const i64, length: usize,
                               output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 1) return -1;
    const limit_value = values[0];
    if (limit_value < 1 or limit_value > MAX_LIMIT) return -1;
    const limit: usize = @intCast(limit_value);
    if (limit <= 2) return 0;
    var divisor_sums: [MAX_LIMIT]i64 = @splat(0);
    for (1..limit) |divisor| {
        var multiple = divisor * 2;
        while (multiple < limit) : (multiple += divisor)
            divisor_sums[multiple] += @intCast(divisor);
    }

    var pair_count: usize = 0;
    for (2..limit) |smaller| {
        const larger = divisor_sums[smaller];
        if (larger > @as(i64, @intCast(smaller)) and larger < limit_value and
            divisor_sums[@intCast(larger)] == @as(i64, @intCast(smaller))) {
            pair_count += 1;
        }
    }
    const required = pair_count * 8;
    if (output_capacity < required or (required != 0 and output == null)) return -2;

    var position: usize = 0;
    for (2..limit) |smaller| {
        const larger = divisor_sums[smaller];
        if (larger > @as(i64, @intCast(smaller)) and larger < limit_value and
            divisor_sums[@intCast(larger)] == @as(i64, @intCast(smaller))) {
            writeU32Le(output, &position, @intCast(smaller));
            writeU32Le(output, &position, larger);
        }
    }
    return @intCast(pair_count);
}
