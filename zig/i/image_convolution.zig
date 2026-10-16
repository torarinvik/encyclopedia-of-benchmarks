const MAX_SIDE: usize = 16;
const MAX_KERNEL_SIDE: usize = 7;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |index| output[offset + index] = @truncate(bits >> @intCast(index * 8));
}

export fn image_convolution(values: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 3 or length > 308) return -1;
    const side_value = values[0];
    const kernel_side_value = values[1];
    if (side_value < 1 or side_value > MAX_SIDE or kernel_side_value < 1 or
        kernel_side_value > MAX_KERNEL_SIDE or @mod(kernel_side_value, 2) == 0) return -1;
    const side: usize = @intCast(side_value);
    const kernel_side: usize = @intCast(kernel_side_value);
    const pixel_count = side * side;
    const kernel_count = kernel_side * kernel_side;
    if (length != 2 + pixel_count + kernel_count) return -1;
    for (0..pixel_count) |index| if (values[2 + index] < 0 or values[2 + index] > 255) return -1;
    for (0..kernel_count) |index| if (values[2 + pixel_count + index] < -16 or values[2 + pixel_count + index] > 16) return -1;
    const output_bytes = pixel_count * 8;
    if (output_capacity < output_bytes) return -2;

    const radius: i64 = @intCast(kernel_side / 2);
    for (0..side) |row| {
        for (0..side) |column| {
            var total: i64 = 0;
            for (0..kernel_side) |kernel_row| {
                const source_row_value = @as(i64, @intCast(row)) + @as(i64, @intCast(kernel_row)) - radius;
                const source_row: usize = @intCast(@max(0, @min(@as(i64, @intCast(side - 1)), source_row_value)));
                for (0..kernel_side) |kernel_column| {
                    const source_column_value = @as(i64, @intCast(column)) + @as(i64, @intCast(kernel_column)) - radius;
                    const source_column: usize = @intCast(@max(0, @min(@as(i64, @intCast(side - 1)), source_column_value)));
                    const pixel = values[2 + source_row * side + source_column];
                    const weight = values[2 + pixel_count + kernel_row * kernel_side + kernel_column];
                    total += pixel * weight;
                }
            }
            storeI64Le(output, (row * side + column) * 8, total);
        }
    }
    return @intCast(output_bytes);
}
