/// Count single-color block replacements for lengths two, three, and four.
const MAX_LENGTH: i64 = 91;

export fn problem116(length: i64) i64 {
    if (length > MAX_LENGTH) return -1;
    if (length < 0) return -1;
    var ways: [276]i64 = @splat(0);
    var row_length: i64 = 0;
    while (row_length <= length) : (row_length += 1) {
        var tile_length: i64 = 2;
        while (tile_length < 5) : (tile_length += 1) {
            const color = tile_length - 2;
            var tile_start: i64 = 0;
            while (tile_start < row_length - tile_length + 1) : (tile_start += 1) {
                const suffix = row_length - tile_start - tile_length;
                const index: usize = @intCast(row_length * 3 + color);
                const suffix_index: usize = @intCast(suffix * 3 + color);
                ways[index] += ways[suffix_index] + 1;
            }
        }
    }
    return ways[@intCast(length * 3)] + ways[@intCast(length * 3 + 1)] + ways[@intCast(length * 3 + 2)];
}
