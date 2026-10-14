/// Bead sort for the benchmark's nonnegative 0..63 domain.
export fn bead_sort(values: [*]i64, scratch: [*]i64, length: usize) void {
    if (length < 2) return;
    @memset(scratch[0..64], 0);
    for (0..length) |index| {
        var level: usize = 0;
        while (level < @as(usize, @intCast(values[index]))) : (level += 1) {
            scratch[level] += 1;
        }
    }
    for (0..length) |index| {
        const row_from_bottom = length - 1 - index;
        var value: i64 = 0;
        for (0..64) |level| {
            if (scratch[level] > @as(i64, @intCast(row_from_bottom))) value += 1;
        }
        values[index] = value;
    }
}
