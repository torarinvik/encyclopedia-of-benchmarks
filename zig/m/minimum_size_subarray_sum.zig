export fn minimum_size_subarray_sum(input_values: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    const target = input_values[0];
    const count = input_values[1];
    if (target < 1 or target > 1_000_000 or count < 0 or count > 256
        or length != @as(usize, @intCast(count)) + 2) return -1;
    const values = input_values[2..length];
    for (values) |value| {
        if (value < 1 or value > 1_000_000) return -1;
    }
    var left: usize = 0;
    var current_sum: i64 = 0;
    var best: usize = values.len + 1;
    for (values, 0..) |value, right| {
        current_sum += value;
        while (current_sum >= target) {
            best = @min(best, right - left + 1);
            current_sum -= values[left];
            left += 1;
        }
    }
    return if (best <= values.len) @intCast(best) else 0;
}
