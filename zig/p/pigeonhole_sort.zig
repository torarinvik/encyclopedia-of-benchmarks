/// Portable pigeonhole sort for signed keys in [-128, 128].
export fn pigeonhole_sort(values: [*]i64, scratch: [*]i64, length: usize) void {
    if (length < 2) return;
    @memset(scratch[0..257], 0);
    for (0..length) |index| {
        const bucket: usize = @intCast(values[index] + 128);
        scratch[bucket] += 1;
    }
    var index: usize = 0;
    for (0..257) |bucket| {
        while (scratch[bucket] > 0) {
            values[index] = @as(i64, @intCast(bucket)) - 128;
            index += 1;
            scratch[bucket] -= 1;
        }
    }
}
