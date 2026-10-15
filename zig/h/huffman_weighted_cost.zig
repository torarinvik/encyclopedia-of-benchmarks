const MAX_SYMBOLS: usize = 26;
const MAX_TOTAL_FREQUENCY: i64 = 2_147_483_647;

fn storeI64Le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
}

export fn huffman_weighted_cost(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > 53) return -1;
    const input = values.?[0..length];
    const raw_count = input[0];
    if (raw_count < 2 or raw_count > MAX_SYMBOLS or length != 1 + 2 * @as(usize, @intCast(raw_count))) return -1;
    const count: usize = @intCast(raw_count);

    var seen: [MAX_SYMBOLS]bool = @splat(false);
    var active: [MAX_SYMBOLS]bool = @splat(false);
    var weights: [MAX_SYMBOLS]i64 = @splat(0);
    var total: i64 = 0;
    for (0..count) |index| {
        const symbol = input[1 + 2 * index];
        const frequency = input[2 + 2 * index];
        if (symbol < 97 or symbol > 122 or frequency < 1 or frequency > MAX_TOTAL_FREQUENCY) return -1;
        const letter: usize = @intCast(symbol - 97);
        if (seen[letter] or total > MAX_TOTAL_FREQUENCY - frequency) return -1;
        seen[letter] = true;
        active[index] = true;
        weights[index] = frequency;
        total += frequency;
    }

    var remaining = count;
    var cost: i64 = 0;
    while (remaining > 1) {
        var first: usize = MAX_SYMBOLS;
        var second: usize = MAX_SYMBOLS;
        for (0..count) |index| {
            if (!active[index]) continue;
            if (first == MAX_SYMBOLS or weights[index] < weights[first]) {
                second = first;
                first = index;
            } else if (second == MAX_SYMBOLS or weights[index] < weights[second]) {
                second = index;
            }
        }
        weights[first] += weights[second];
        active[second] = false;
        cost += weights[first];
        remaining -= 1;
    }

    if (output == null or output_capacity < 8) return -2;
    storeI64Le(output.?[0..8].ptr, cost);
    return cost;
}
