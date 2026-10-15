const MAX_LENGTH: usize = 10000;

/// Return the longest strictly increasing contiguous run.
export fn longest_continuous_increasing_subsequence(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        if (values[index] < -1_000_000 or values[index] > 1_000_000) return -1;
    }
    if (length == 0) return 0;

    var current: i64 = 1;
    var best: i64 = 1;
    for (1..length) |index| {
        if (values[index] > values[index - 1]) current += 1
        else current = 1;
        if (current > best) best = current;
    }
    return best;
}
