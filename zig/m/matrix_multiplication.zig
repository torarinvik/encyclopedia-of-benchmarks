fn storeI64Le(value: i64, output: []u8, offset: usize) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

/// Multiply two bounded square integer matrices into row-major little-endian i64 cells.
export fn matrix_multiplication(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 1) return -2;
    const values = input.?[0..length];
    const dimension = values[0];
    if (dimension < 2 or dimension > 8) return -2;
    const n: usize = @intCast(dimension);
    const cells = n * n;
    if (length != 1 + 2 * cells) return -2;
    for (values[1..]) |value| {
        if (value < -1000 or value > 1000) return -2;
    }
    if (output == null or output_capacity < cells * 8) return -3;
    const out = output.?[0..output_capacity];
    for (0..n) |row| {
        for (0..n) |column| {
            var sum: i64 = 0;
            for (0..n) |index| {
                sum += values[1 + row * n + index] * values[1 + cells + index * n + column];
            }
            storeI64Le(sum, out, (row * n + column) * 8);
        }
    }
    return @intCast(cells);
}
