export fn booths_algorithm(values: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (values == null or length == 0 or length > 256) return -1;
    for (0..length) |index| {
        const value = values.?[index];
        if (value < 0 or value > 127) return -1;
    }
    if (output == null or capacity < length) return -2;

    var failure = [_]i64{-1} ** 512;
    var start: usize = 0;
    for (1..2 * length) |j| {
        const current = values.?[j % length];
        var matched = failure[j - start - 1];
        while (matched != -1 and current != values.?[(start + @as(usize, @intCast(matched)) + 1) % length]) {
            if (current < values.?[(start + @as(usize, @intCast(matched)) + 1) % length]) {
                start = j - @as(usize, @intCast(matched)) - 1;
            }
            matched = failure[@intCast(matched)];
        }
        if (matched == -1 and current != values.?[start % length]) {
            if (current < values.?[start % length]) start = j;
            failure[j - start] = -1;
        } else {
            failure[j - start] = matched + 1;
        }
    }

    for (0..length) |index| {
        output.?[index] = @intCast(values.?[(start + index) % length]);
    }
    return @intCast(length);
}
