export fn minimum_window_subsequence(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 258) return -1;
    if (input[0] < 0 or input[0] > 128) return -1;
    const search_length: usize = @intCast(input[0]);
    const pattern_length_index = search_length + 1;
    if (length <= pattern_length_index) return -1;
    const pattern_length_value = input[pattern_length_index];
    if (pattern_length_value < 1 or pattern_length_value > 128) return -1;
    const pattern_length: usize = @intCast(pattern_length_value);
    if (length != search_length + pattern_length + 2) return -1;
    for (0..search_length) |i| {
        if (input[i + 1] < 0 or input[i + 1] > 127) return -1;
    }
    for (0..pattern_length) |j| {
        if (input[search_length + 2 + j] < 0 or input[search_length + 2 + j] > 127) return -1;
    }

    var latest_start = [_]i8{-1} ** 128;
    var best_start: isize = -1;
    var best_length = search_length + 1;
    for (0..search_length) |end| {
        const byte = input[end + 1];
        for (0..pattern_length) |offset| {
            const pattern_index = pattern_length - 1 - offset;
            if (byte != input[search_length + 2 + pattern_index]) continue;
            const candidate: isize = if (pattern_index == 0)
                @intCast(end)
            else
                latest_start[pattern_index - 1];
            if (candidate >= 0 and candidate > @as(isize, latest_start[pattern_index]))
                latest_start[pattern_index] = @intCast(candidate);
        }
        if (byte == input[search_length + 2 + pattern_length - 1] and latest_start[pattern_length - 1] >= 0) {
            const start: usize = @intCast(latest_start[pattern_length - 1]);
            const window_length = end - start + 1;
            if (window_length < best_length or
                (window_length == best_length and (best_start < 0 or @as(isize, @intCast(start)) < best_start))) {
                best_start = @intCast(start);
                best_length = window_length;
            }
        }
    }
    if (best_start < 0) return 0;
    if (best_length > capacity or output == null) return -2;
    for (0..best_length) |i| output[i] = @intCast(input[@as(usize, @intCast(best_start)) + 1 + i]);
    return @intCast(best_length);
}
