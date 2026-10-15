const MAX_LENGTH: usize = 256;

pub export fn z_function(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (length > MAX_LENGTH or (length > 0 and input == null)) return -1;
    for (0..length) |index| {
        if (input[index] < 0 or input[index] > 127) return -1;
    }
    const required = length * 8;
    if (capacity < required or (required > 0 and output == null)) return -2;

    var z = [_]i64{0} ** MAX_LENGTH;
    var left: usize = 0;
    var right: usize = 0;
    for (1..length) |index| {
        if (index <= right) {
            const prior: usize = @intCast(z[index - left]);
            const window = right - index + 1;
            z[index] = @intCast(@min(window, prior));
        }
        while (index + @as(usize, @intCast(z[index])) < length and
               input[@intCast(z[index])] == input[index + @as(usize, @intCast(z[index]))]) {
            z[index] += 1;
        }
        if (index + @as(usize, @intCast(z[index])) > right + 1) {
            left = index;
            right = index + @as(usize, @intCast(z[index])) - 1;
        }
    }
    for (0..length) |index| {
        const bytes = @as(u64, @intCast(z[index]));
        for (0..8) |byte| output[index * 8 + byte] = @truncate(bytes >> @intCast(8 * byte));
    }
    return @intCast(required);
}
