export fn problem115(min_block_length: i64) i64 {
    if (min_block_length < 1 or min_block_length > 100) return -1;
    var ways = [_]i64{0} ** 1024;
    const minimum: usize = @intCast(min_block_length);
    for (0..minimum) |i| ways[i] = 1;
    for (minimum..1024) |n| {
        ways[n] = 1;
        for (minimum..(n + 1)) |block_length| {
            for (0..(n - block_length)) |block_start| {
                ways[n] += ways[n - block_start - block_length - 1];
            }
            ways[n] += 1;
        }
        if (ways[n] > 1000000) return @intCast(n);
    }
    return -1;
}
