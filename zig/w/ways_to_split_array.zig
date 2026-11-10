/// Count positions where the prefix sum is at least the remaining suffix sum.
const MAX_LENGTH: usize = 100_000;
const MAX_VALUE: i64 = 100_000;

export fn ways_to_split_array(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_LENGTH) return -1;
    var total: u64 = 0;
    var largest_biased_value: u64 = 0;
    for (0..length) |index| {
        const value: u64 = @bitCast(values[index]);
        largest_biased_value = @max(largest_biased_value, value +% @as(u64, MAX_VALUE));
        total +%= value;
    }
    if (largest_biased_value > 2 * @as(u64, MAX_VALUE)) return -1;
    const signed_total: i64 = @bitCast(total +% 1);
    const threshold = signed_total >> 1;
    var prefix: u64 = 0;
    var ways: i64 = 0;
    for (0..length - 1) |index| {
        prefix +%= @as(u64, @bitCast(values[index]));
        if (@as(i64, @bitCast(prefix)) >= threshold) ways += 1;
    }
    return ways;
}
