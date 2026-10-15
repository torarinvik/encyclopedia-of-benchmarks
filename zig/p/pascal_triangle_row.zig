/// Compute one row of Pascal's triangle using in-place dynamic programming.
export fn pascal_triangle_row(row_index: i64, output: [*]u8,
    output_capacity: usize) i64 {
    if (row_index < 0 or row_index > 33) return -1;
    const count: usize = @intCast(row_index + 1);
    const required = count * 4;
    if (output_capacity < required) return -2;

    var coefficients: [34]u32 = undefined;
    for (0..count) |column| {
        coefficients[column] = 1;
    }
    var row: usize = 2;
    while (row <= @as(usize, @intCast(row_index))) : (row += 1) {
        var column = row - 1;
        while (column > 0) : (column -= 1) {
            coefficients[column] += coefficients[column - 1];
        }
    }

    var position: usize = 0;
    for (0..count) |column| {
        for (0..4) |byte| {
            output[position] = @truncate(coefficients[column] >> @as(u5, @intCast(byte * 8)));
            position += 1;
        }
    }
    return @intCast(position);
}
