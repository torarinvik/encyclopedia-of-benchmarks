const CS = [_]i64{0x0db84a81, 0x0e1b9d7f, 0x0f31adcf, 0x0fbba815, 0x0feda417, 0x0ffc8fc8, 0x0fff964c, 0x0ffff8d3};
const CA = [_]i64{-0x083b5fe7, -0x078c36d2, -0x05039814, -0x02e91dd1, -0x0183603a, -0x00a7cb87, -0x003a2847, -0x000f27b4};

fn floorDiv(value: i64, divisor: i64) i64 {
    const quotient = @divTrunc(value, divisor);
    if (@rem(value, divisor) < 0) return quotient - 1;
    return quotient;
}

fn madMul(left: i64, right: i64) i64 {
    return floorDiv(left + 2048, 4096) * floorDiv(right + 32768, 65536);
}

fn putI32Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn cbench_consumer_mad_alias_reduce(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 65) return -1;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > 4) return -1;
    const boundaries: usize = @intCast(values[0]);
    if (length != 1 + 16 * boundaries) return -1;
    for (values[1..]) |value| if (value < -100_000_000 or value > 100_000_000) return -1;
    const output_size = 64 * boundaries;
    var staged: [64]i64 = @splat(0);
    for (0..boundaries) |boundary| {
        const base = 1 + 16 * boundary;
        for (0..8) |i| {
            const a = values[base + 2 * i];
            const b = values[base + 2 * i + 1];
            staged[16 * boundary + 2 * i] = madMul(a, CS[i]) + madMul(-b, CA[i]);
            staged[16 * boundary + 2 * i + 1] = madMul(b, CS[i]) + madMul(a, CA[i]);
        }
    }
    if (output == null or capacity < output_size) return -2;
    const result = output.?;
    for (0..16 * boundaries) |i| putI32Le(result, 4 * i, staged[i]);
    return @intCast(output_size);
}
