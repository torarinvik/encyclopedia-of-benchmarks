/// Divide-and-conquer maximum nonempty contiguous-subarray sum.
fn max_subarray_range(values: [*]const i64, start: usize, end: usize) i64 {
    if (end - start == 1) return values[start];
    const middle = start + (end - start) / 2;
    const left_best = max_subarray_range(values, start, middle);
    const right_best = max_subarray_range(values, middle, end);
    var running = values[middle - 1];
    var left_suffix = running;
    var index = middle - 1;
    while (index > start) {
        index -= 1;
        running += values[index];
        if (running > left_suffix) left_suffix = running;
    }
    running = values[middle];
    var right_prefix = running;
    index = middle + 1;
    while (index < end) : (index += 1) {
        running += values[index];
        if (running > right_prefix) right_prefix = running;
    }
    const crossing = left_suffix + right_prefix;
    const best = @max(left_best, right_best);
    return @max(best, crossing);
}

export fn max_subarray(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 1024) return -1;
    for (0..length) |index| {
        if (values[index] < -2147483648 or values[index] > 2147483647) return -1;
    }
    return max_subarray_range(values, 0, length);
}
