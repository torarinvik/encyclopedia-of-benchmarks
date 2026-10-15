const MAX_ITEMS: usize = 256;
const RNG_MODULUS: i64 = 2147483647;
const RNG_PERIOD: i64 = 2147483646;

export fn naive_shuffler(input: [*]const i64, length: usize, output: [*]u8,
    output_capacity: usize) i64 {
    if (length < 2 or length > MAX_ITEMS + 2) return -1;
    const seed = input[0];
    const count_value = input[1];
    if (seed < 0 or seed >= RNG_PERIOD or count_value < 0 or count_value > MAX_ITEMS) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 2) return -1;

    var items: [MAX_ITEMS]u8 = undefined;
    @memset(&items, 0);
    for (0..count) |index| {
        const value = input[index + 2];
        if (value < 0 or value > 255) return -1;
        items[index] = @intCast(value);
    }
    if (output_capacity < count) return -2;

    var state = seed + 1;
    for (0..count) |index| {
        const bound: i64 = @intCast(count);
        const limit = RNG_PERIOD - @mod(RNG_PERIOD, bound);
        var sample: i64 = 0;
        while (true) {
            state = @mod(state * 48271, RNG_MODULUS);
            sample = state - 1;
            if (sample < limit) break;
        }
        const other: usize = @intCast(@mod(sample, bound));
        const temporary = items[index];
        items[index] = items[other];
        items[other] = temporary;
    }
    for (0..count) |index| output[index] = items[index];
    return @intCast(count);
}
