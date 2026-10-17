export fn long_utils(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > 3 or values[2] < 0 or values[2] > 63) return -1;
    if (output == null or capacity < 8) return -2;
    const bits: u64 = @bitCast(values[1]);
    const distance: usize = @intCast(values[2]);
    var rotated = bits;
    if (distance != 0) {
        if (values[0] < 2) rotated = (bits << distance) | (bits >> (64 - distance))
        else rotated = (bits >> distance) | (bits << (64 - distance));
    }
    const destination = output.?;
    for (0..8) |byte| destination[byte] = @truncate(rotated >> @intCast(8 * byte));
    return 8;
}
