export fn unique_occurrences(values: [*]const i64, length: usize) i64 {
    if (length > 1000) return -1;
    var counts: [2001]i64 = @splat(0);
    var seen_frequencies: [1001]bool = @splat(false);
    for (0..length) |index| {
        const value = values[index];
        if (value < -1000 or value > 1000) return -1;
        counts[@intCast(value + 1000)] += 1;
    }
    for (counts) |frequency| {
        if (frequency == 0) continue;
        const frequency_index: usize = @intCast(frequency);
        if (seen_frequencies[frequency_index]) return 0;
        seen_frequencies[frequency_index] = true;
    }
    return 1;
}
