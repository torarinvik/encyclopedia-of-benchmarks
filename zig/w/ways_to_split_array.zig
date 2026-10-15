/// Count positions where the prefix sum is at least the remaining suffix sum.
const MAX_LENGTH: usize = 100_000;
const MAX_VALUE: i64 = 100_000;

export fn ways_to_split_array(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_LENGTH) return -1;
    var total_sum: i64 = 0;
    for (0..length) |index| {
        if (values[index] < -MAX_VALUE or values[index] > MAX_VALUE) return -1;
        total_sum += values[index];
    }
    var prefix_sum: i64 = 0;
    var ways: i64 = 0;
    for (0..length - 1) |index| {
        prefix_sum += values[index];
        if (prefix_sum >= total_sum - prefix_sum) ways += 1;
    }
    return ways;
}
