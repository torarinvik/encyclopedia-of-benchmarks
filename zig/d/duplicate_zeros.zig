/// Duplicate each zero while retaining the fixed output length.
fn writeI32(output: [*]u8, position: usize, value: i64) void {
    const encoded: u32 = @bitCast(@as(i32, @intCast(value)));
    output[position] = @truncate(encoded);
    output[position + 1] = @truncate(encoded >> 8);
    output[position + 2] = @truncate(encoded >> 16);
    output[position + 3] = @truncate(encoded >> 24);
}

export fn duplicate_zeros(values: [*]const i64, length: usize,
                          output: [*]u8, output_capacity: usize) i64 {
    if (length > 64) return -1;
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > 1000) return -1;
    }
    const required = 4 * length;
    if (output_capacity < required) return -2;
    var source: usize = 0;
    var destination: usize = 0;
    while (destination < length) {
        const value = values[source];
        source += 1;
        writeI32(output, 4 * destination, value);
        destination += 1;
        if (value == 0 and destination < length) {
            writeI32(output, 4 * destination, 0);
            destination += 1;
        }
    }
    return @intCast(length);
}
