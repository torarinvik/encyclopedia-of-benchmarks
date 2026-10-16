const MAX_LENGTH: i64 = 50;

pub export fn problem114(length: i64) i64 {
    if (length < 0 or length > MAX_LENGTH) return -1;
    var ways: [51]i64 = undefined;
    for (0..@as(usize, @intCast(length)) + 1) |index| ways[index] = 1;
    var row_length: i64 = 3;
    while (row_length <= length) : (row_length += 1) {
        var block_length: i64 = 3;
        while (block_length <= row_length) : (block_length += 1) {
            var block_start: i64 = 0;
            while (block_start < row_length - block_length) : (block_start += 1) {
                ways[@intCast(row_length)] += ways[@intCast(row_length - block_start - block_length - 1)];
            }
            ways[@intCast(row_length)] += 1;
        }
    }
    return ways[@intCast(length)];
}
