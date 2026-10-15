/// Return the longest run of ones in a binary array.
export fn max_consecutive_ones(values: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    var best: usize = 0;
    var run: usize = 0;
    for (0..length) |index| {
        if (values[index] != 0 and values[index] != 1) return -1;
        if (values[index] == 1) {
            run += 1;
            if (run > best) best = run;
        } else {
            run = 0;
        }
    }
    return @intCast(best);
}
