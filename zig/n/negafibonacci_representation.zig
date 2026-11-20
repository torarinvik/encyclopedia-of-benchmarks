const MAX_INDEX: usize = 17;
const VALUE_LIMIT: i64 = 1000;

fn encode(value: i64, output: *[MAX_INDEX]u8) usize {
    var fib: [MAX_INDEX + 1]i64 = @splat(0);
    var weight: [MAX_INDEX + 1]i64 = @splat(0);
    var low: [MAX_INDEX + 1]i64 = @splat(0);
    var high: [MAX_INDEX + 1]i64 = @splat(0);
    var digit: [MAX_INDEX + 1]bool = @splat(false);
    fib[1] = 1;
    fib[2] = 1;
    for (3..MAX_INDEX + 1) |k| fib[k] = fib[k - 1] + fib[k - 2];
    for (1..MAX_INDEX + 1) |k| weight[k] = if (k % 2 == 1) fib[k] else -fib[k];
    for (1..MAX_INDEX + 1) |k| {
        const suffix_low: i64 = if (k == 1) 0 else low[k - 2];
        const suffix_high: i64 = if (k == 1) 0 else high[k - 2];
        const with_low = weight[k] + suffix_low;
        const with_high = weight[k] + suffix_high;
        low[k] = @min(low[k - 1], with_low);
        high[k] = @max(high[k - 1], with_high);
    }
    var remaining = value;
    var selected_above = false;
    var k = MAX_INDEX;
    while (k > 0) : (k -= 1) {
        var choose = false;
        if (!selected_above) {
            const suffix_low: i64 = if (k == 1) 0 else low[k - 2];
            const suffix_high: i64 = if (k == 1) 0 else high[k - 2];
            const candidate = remaining - weight[k];
            choose = suffix_low <= candidate and candidate <= suffix_high;
        }
        if (choose) { digit[k] = true; remaining -= weight[k]; }
        selected_above = choose;
    }
    var highest = MAX_INDEX;
    while (highest > 1 and !digit[highest]) : (highest -= 1) {}
    k = highest;
    var written: usize = 0;
    while (k > 0) : (k -= 1) {
        output[written] = if (digit[k]) '1' else '0';
        written += 1;
    }
    return written;
}

export fn negafibonacci_representation(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length != 1) return -1;
    const value = input.?[0];
    if (value < -VALUE_LIMIT or value > VALUE_LIMIT) return -1;
    var staged: [MAX_INDEX]u8 = @splat(0);
    const required = encode(value, &staged);
    if (output == null or output_capacity < required) return -2;
    for (0..required) |index| output.?[index] = staged[index];
    return @intCast(required);
}
