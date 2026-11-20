export fn gray_code_k_combinations(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 12 or values[1] < 0 or values[1] > values[0]) return -1;
    const n: usize = @intCast(values[0]);
    const k: usize = @intCast(values[1]);
    const smaller = @min(k, n - k);
    var count: usize = 1;
    for (1..(smaller + 1)) |factor| count = count * (n - smaller + factor) / factor;
    const required = 2 + 2 * count;
    if (output == null or capacity < required) return -2;
    const bytes = output.?[0..required];
    bytes[0] = @truncate(count);
    bytes[1] = @truncate(count >> 8);

    var emitted: usize = 0;
    for (0..(@as(usize, 1) << n)) |index| {
        const mask = index ^ (index >> 1);
        var remaining = mask;
        var population: usize = 0;
        while (remaining != 0) {
            remaining &= remaining - 1;
            population += 1;
        }
        if (population == k) {
            bytes[2 + 2 * emitted] = @truncate(mask);
            bytes[3 + 2 * emitted] = @truncate(mask >> 8);
            emitted += 1;
        }
    }
    return @intCast(count);
}
