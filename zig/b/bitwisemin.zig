const max_length: usize = 4096;
const max_value: i64 = 2_147_483_647;

/// Reduce the input array to its minimum with a sign-bit mask.
export fn bitwisemin(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > max_length) return -1;
    var minimum = values[0];
    if (minimum < 0 or minimum > max_value) return -1;
    for (1..length) |index| {
        const value = values[index];
        if (value < 0 or value > max_value) return -1;
        const difference = minimum - value;
        const sign = (@as(u32, @truncate(difference)) >> 31) & 1;
        const keep_minimum: u32 = 0xFFFF_FFFF * sign;
        minimum = @as(i64, @intCast((@as(u32, @intCast(minimum)) & keep_minimum) |
            (@as(u32, @intCast(value)) & ~keep_minimum)));
    }
    return minimum;
}
