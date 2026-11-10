export fn smallest_divisor(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 257) return -1;
    const count: u64 = @intCast(length - 1);
    const threshold: u64 = @bitCast(input[0]);
    if (threshold < count or threshold > 1_000_000) return -1;
    var maximum: u64 = 0;
    var total: u64 = 0;
    for (1..length) |index| {
        const value: u64 = @bitCast(input[index]);
        if (value == 0 or value > 1_000_000) return -1;
        maximum = @max(maximum, value);
        total += value;
    }
    if (threshold == count) return @intCast(maximum);

    var low = (total - 1) / threshold + 1;
    const upper_bound = (total - count) / (threshold - count + 1) + 1;
    var high = @min(maximum, upper_bound);
    while (low < high) {
        const middle = low + ((high - low) >> 1);
        var rounded_sum = count;
        if (count <= 4) {
            for (1..length) |index| {
                const value: u32 = @intCast(input[index]);
                rounded_sum += (value - 1) / @as(u32, @intCast(middle));
            }
        } else {
            const reciprocal = (1_099_511_627_775 / middle) + 1;
            for (1..length) |index| {
                const value: u64 = @intCast(input[index]);
                rounded_sum += ((value - 1) * reciprocal) >> 40;
            }
        }
        if (rounded_sum <= threshold) high = middle else low = middle + 1;
    }
    return @intCast(low);
}
