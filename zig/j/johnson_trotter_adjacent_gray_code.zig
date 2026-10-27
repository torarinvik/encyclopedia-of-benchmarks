const MAX_N: usize = 3;
const MAX_OUTPUT_BYTES: usize = 144;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn johnson_trotter_adjacent_gray_code(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, MAX_N)) return -1;
    const n: usize = @intCast(input[0]);
    var permutation_count: usize = 1;
    var value: usize = 2;
    while (value <= n) : (value += 1) permutation_count *= value;
    const output_bytes = 8 * n * permutation_count;
    if (output_opt == null or capacity < output_bytes) return -2;
    var permutation: [MAX_N]i64 = @splat(0);
    var direction: [MAX_N + 1]i64 = @splat(0);
    for (0..n) |index| {
        permutation[index] = @intCast(index + 1);
        direction[index + 1] = -1;
    }
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var rows: usize = 0;
    while (true) {
        for (0..n) |index| store_i64_le(&staged, 8 * (rows * n + index), permutation[index]);
        rows += 1;
        var largest_mobile: i64 = 0;
        var mobile_position: usize = n;
        for (0..n) |position| {
            const item = permutation[position];
            const neighbor = @as(i64, @intCast(position)) + direction[@intCast(item)];
            if (neighbor >= 0 and neighbor < @as(i64, @intCast(n)) and item > permutation[@intCast(neighbor)] and item > largest_mobile) {
                largest_mobile = item;
                mobile_position = position;
            }
        }
        if (mobile_position == n) break;
        const neighbor = @as(usize, @intCast(@as(i64, @intCast(mobile_position)) + direction[@intCast(largest_mobile)]));
        const temporary = permutation[mobile_position];
        permutation[mobile_position] = permutation[neighbor];
        permutation[neighbor] = temporary;
        value = @intCast(largest_mobile + 1);
        while (value <= n) : (value += 1) direction[value] = -direction[value];
    }
    const output = output_opt.?;
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
