/// Return the earliest split with the smallest difference of integer averages.
const MAX_LENGTH: usize = 100_000;
const MAX_VALUE: i64 = 100_000;

export fn minimum_average_difference(values: [*c]const i64, length: usize) i64 {
    if (values == null or length == 0 or length > MAX_LENGTH) return -1;
    var total_sum: i64 = 0;
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > MAX_VALUE) return -1;
        total_sum += values[index];
    }
    var prefix_sum: i64 = 0;
    var best_difference: i64 = 9223372036854775807;
    var best_index: usize = 0;
    for (0..length) |index| {
        prefix_sum += values[index];
        const left_average = @divTrunc(prefix_sum, @as(i64, @intCast(index + 1)));
        const suffix_length = length - index - 1;
        const right_average = if (suffix_length == 0) 0 else
            @divTrunc(total_sum - prefix_sum, @as(i64, @intCast(suffix_length)));
        const difference = if (left_average >= right_average)
            left_average - right_average
        else
            right_average - left_average;
        if (difference < best_difference) {
            best_difference = difference;
            best_index = index;
        }
    }
    return @intCast(best_index);
}
