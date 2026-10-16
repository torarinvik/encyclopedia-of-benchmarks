const MAX_INPUT_LENGTH: usize = 2 + 16 * 16 + 9;

fn put_i32_le(output: [*c]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn dilation_operation(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 12 or length > MAX_INPUT_LENGTH) return -1;
    const rows_value = input[0];
    const columns_value = input[1];
    if (rows_value < 1 or rows_value > 16 or columns_value < 1 or columns_value > 16) return -1;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    const cells = rows * columns;
    if (length != 2 + cells + 9) return -1;
    for (0..cells + 9) |index| {
        const value = input[2 + index];
        if (value < 0 or value > 1) return -1;
    }
    if (output == null or output_capacity < cells * 4) return -2;
    for (0..rows) |y| {
        for (0..columns) |x| {
            var sum: i32 = 0;
            for (0..3) |ky| {
                for (0..3) |kx| {
                    const image_y: isize = @as(isize, @intCast(y)) + @as(isize, @intCast(ky)) - 1;
                    const image_x: isize = @as(isize, @intCast(x)) + @as(isize, @intCast(kx)) - 1;
                    if (image_y >= 0 and image_y < @as(isize, @intCast(rows)) and image_x >= 0 and
                        image_x < @as(isize, @intCast(columns))) {
                        sum += @intCast(input[2 + @as(usize, @intCast(image_y)) * columns + @as(usize, @intCast(image_x))] *
                            input[2 + cells + ky * 3 + kx]);
                    }
                }
            }
            put_i32_le(output, (y * columns + x) * 4, if (sum > 0) 1 else 0);
        }
    }
    return @intCast(cells);
}
