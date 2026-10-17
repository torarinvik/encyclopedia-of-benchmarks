const MIN_TARGET: i64 = -4096;
const MAX_TARGET: i64 = 4096;
const MAX_DENOMINATIONS: usize = 32;
const MAX_INPUT_VALUES: usize = 2 + MAX_DENOMINATIONS;
const MAX_OUTPUT_BYTES: usize = (1 + 4096) * 4;

fn writeI32Le(output: []u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn minimum_coin_change_greedy(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const values = input.?[0..length];
    const target = values[0];
    const count_value = values[1];
    if (target < MIN_TARGET or target > MAX_TARGET or count_value < 0 or count_value > 32) return -1;
    const denomination_count: usize = @intCast(count_value);
    if (length != 2 + denomination_count) return -1;

    var denominations: [MAX_DENOMINATIONS]i32 = @splat(0);
    var previous: i64 = 0;
    for (0..denomination_count) |index| {
        const denomination = values[2 + index];
        if (denomination < 1 or denomination > 4096 or denomination <= previous) return -1;
        denominations[index] = @intCast(denomination);
        previous = denomination;
    }

    var chosen: [4096]i32 = @splat(0);
    var chosen_count: usize = 0;
    if (target > 0) {
        var remaining = target;
        var index = denomination_count;
        while (index > 0) {
            index -= 1;
            const denomination = denominations[index];
            const coin_value: i64 = @intCast(denomination);
            while (remaining >= coin_value) {
                remaining -= coin_value;
                chosen[chosen_count] = denomination;
                chosen_count += 1;
            }
        }
    }

    const needed = (1 + chosen_count) * 4;
    if (output == null or capacity < needed) return -2;
    var buffer: [MAX_OUTPUT_BYTES]u8 = undefined;
    writeI32Le(buffer[0..], 0, @intCast(chosen_count));
    for (0..chosen_count) |index| writeI32Le(buffer[0..], 4 + 4 * index, chosen[index]);
    for (0..needed) |index| output.?[index] = buffer[index];
    return @intCast(needed);
}
