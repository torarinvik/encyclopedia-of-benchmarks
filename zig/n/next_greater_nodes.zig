/// Brute-force next-greater-value search for each node in list order.
export fn next_greater_nodes(values: [*]const i64, length: usize,
                             output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 4096) return -1;
    for (0..length) |index| {
        if (values[index] < 1 or values[index] > 1_000_000_000) return -1;
    }
    const required = 4 * length;
    if (output_capacity < required) return -2;
    for (0..length) |index| {
        var next_greater: i64 = 0;
        for (index + 1..length) |later| {
            if (values[later] > values[index]) {
                next_greater = values[later];
                break;
            }
        }
        const encoded: u32 = @intCast(next_greater);
        output[4 * index] = @intCast(encoded & 0xff);
        output[4 * index + 1] = @intCast((encoded >> 8) & 0xff);
        output[4 * index + 2] = @intCast((encoded >> 16) & 0xff);
        output[4 * index + 3] = @intCast((encoded >> 24) & 0xff);
    }
    return @intCast(length);
}
