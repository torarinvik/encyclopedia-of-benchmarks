/// Kadane's maximum nonempty contiguous-subarray sum.
export fn maximum_subarray(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 1024) return -1;
    for (0..length) |index| {
        if (values[index] < -2147483648 or values[index] > 2147483647) return -1;
    }
    var current = values[0];
    var best = current;
    for (1..length) |index| {
        current = if (current > 0) current + values[index] else values[index];
        if (current > best) best = current;
    }
    return best;
}
