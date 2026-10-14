/// Counting sort for signed keys in the inclusive range [-128, 128].
export fn counting_sort(values: [*]i64, counts: [*]i64, length: usize) void {
    if (length < 2) return;
    @memset(counts[0..257], 0);
    for (values[0..length]) |value| {
        const bucket: usize = @intCast(value + 128);
        counts[bucket] += 1;
    }
    var output: usize = 0;
    for (0..257) |bucket| {
        while (counts[bucket] > 0) {
            values[output] = @as(i64, @intCast(bucket)) - 128;
            output += 1;
            counts[bucket] -= 1;
        }
    }
}
