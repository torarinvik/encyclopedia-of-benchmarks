const MAX_COUNT: i64 = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 3;
const MAX_OUTPUT_BYTES: usize = 8 * 64;

fn generateNthTerm(index: i64) i64 {
    if (index == 0 or index == 1) return index;
    if (@mod(index, 2) == 0) return 4 * generateNthTerm(@divTrunc(index, 2));
    return 4 * generateNthTerm(@divTrunc(index, 2)) + 1;
}

fn putI64Le(value: i64, output: [*]u8, offset: usize) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn sequence(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = values.?;
    if (length != 1 or input[0] < -MAX_COUNT or input[0] > MAX_COUNT) return -1;
    if (input[0] <= 0) return 0;

    const count: usize = @intCast(input[0]);
    const required = count * 8;
    if (output == null or output_capacity < required or required > MAX_OUTPUT_BYTES) return -2;
    const destination = output.?;
    for (0..count) |index| {
        putI64Le(generateNthTerm(@intCast(index)), destination, index * 8);
    }
    return @intCast(required);
}
