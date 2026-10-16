const MAX_VALUES: usize = 64;
const MODULUS: u64 = 2_147_483_647;

fn shuffleRecursive(values: *[MAX_VALUES]i32, item: isize, state: *u64) void {
    if (item <= 0) return;
    shuffleRecursive(values, item - 1, state);
    state.* = (state.* * 48_271) % MODULUS;
    const other: usize = @intCast(state.* % @as(u64, @intCast(item + 1)));
    const index: usize = @intCast(item);
    const temporary = values.*[index];
    values.*[index] = values.*[other];
    values.*[other] = temporary;
}

export fn recursive_shuffler(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_VALUES + 1) return -1;
    const values_in = input.?[0..length];
    const seed = values_in[0];
    if (seed < 1 or seed >= 2_147_483_647) return -1;
    const count = length - 1;
    var values: [MAX_VALUES]i32 = @splat(0);
    for (0..count) |index| {
        const value = values_in[index + 1];
        if (value < -2_147_483_648 or value > 2_147_483_647) return -1;
        values[index] = @intCast(value);
    }
    const byte_count = count * 4;
    if (output_capacity < byte_count or (byte_count != 0 and output == null)) return -2;
    var state: u64 = @intCast(seed);
    if (count > 1) shuffleRecursive(&values, @intCast(count - 1), &state);
    if (count != 0) {
        const bytes = output.?[0..byte_count];
        for (0..count) |index| {
            const bits: u32 = @bitCast(values[index]);
            for (0..4) |byte| bytes[index * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
        }
    }
    return @intCast(count);
}
