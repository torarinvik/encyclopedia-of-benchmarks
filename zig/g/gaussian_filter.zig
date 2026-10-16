const SCALE: i64 = 1_000_000_000_000_000;

fn gaussianFilterWeight(kernel_size: i64, distance: i64) i64 {
    if (kernel_size == 3) {
        if (distance == 0) return 159154943091895;
        if (distance == 1) return 96532352630054;
        return 58549831524319;
    }
    if (distance == 0) return 198943678864869;
    if (distance == 1) return 91083053297916;
    if (distance == 2) return 41700860491808;
    if (distance == 4) return 8740975213082;
    if (distance == 5) return 4001910066968;
    return 384051647741;
}

export fn gaussian_filter(values: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (length < 3) return -1;
    const height = values[0];
    const width = values[1];
    const kernel_size = values[2];
    if (height < 3 or height > 12 or width < 3 or width > 12) return -1;
    if (kernel_size != 3 and kernel_size != 5) return -1;
    if (height < kernel_size or width < kernel_size) return -1;
    if (length != 3 + @as(usize, @intCast(height * width))) return -1;
    for (3..length) |index| {
        if (values[index] < 0 or values[index] > 255) return -1;
    }

    const output_height: usize = @intCast(height - kernel_size + 1);
    const output_width: usize = @intCast(width - kernel_size + 1);
    const output_count = output_height * output_width;
    if (capacity < output_count) return -2;
    const center = @divTrunc(kernel_size, 2);
    for (0..output_height) |row| {
        for (0..output_width) |column| {
            var total: i64 = 0;
            var kernel_row: i64 = 0;
            while (kernel_row < kernel_size) : (kernel_row += 1) {
                const dy = kernel_row - center;
                var kernel_column: i64 = 0;
                while (kernel_column < kernel_size) : (kernel_column += 1) {
                    const dx = kernel_column - center;
                    const pixel_index = 3 + (row + @as(usize, @intCast(kernel_row)))
                        * @as(usize, @intCast(width)) + column + @as(usize, @intCast(kernel_column));
                    total += values[pixel_index] * gaussianFilterWeight(kernel_size, dx * dx + dy * dy);
                }
            }
            output[row * output_width + column] = @intCast(@divTrunc(total, SCALE));
        }
    }
    return @intCast(output_count);
}
