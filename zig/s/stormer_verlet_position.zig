const MAX_STEPS: usize = 32;
const MAX_INPUT_VALUES: usize = MAX_STEPS + 1;
const MAX_OUTPUT_BYTES: usize = MAX_STEPS * 8;

fn storeI64Le(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn stormer_verlet_position(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_VALUES) return -1;
    const count_value = input[0];
    if (count_value < 2 or count_value > @as(i64, @intCast(MAX_STEPS))) return -1;
    if (length != @as(usize, @intCast(count_value)) + 1) return -1;
    if (input[1] < -1024 or input[1] > 1024 or input[2] < -1024 or input[2] > 1024) return -1;
    const count: usize = @intCast(count_value);
    for (0..(count - 2)) |step| {
        if (input[3 + step] < -64 or input[3 + step] > 64) return -1;
    }

    const byte_count = 8 * count;
    if (output == null or output_capacity < byte_count) return -2;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var previous = input[1];
    var current = input[2];
    storeI64Le(&staged, 0, previous);
    storeI64Le(&staged, 8, current);
    for (2..count) |index| {
        const next = 2 * current - previous + input[index + 1];
        storeI64Le(&staged, 8 * index, next);
        previous = current;
        current = next;
    }
    for (0..byte_count) |byte| output[byte] = staged[byte];
    return @intCast(byte_count);
}
