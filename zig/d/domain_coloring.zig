const MAX_OUTPUT_BYTES: usize = 768;

fn phaseHue(real_part: i64, imaginary_part: i64) i64 {
    if (real_part == 0 and imaginary_part == 0) return 0;
    const abs_real = if (real_part < 0) -real_part else real_part;
    const abs_imaginary = if (imaginary_part < 0) -imaginary_part else imaginary_part;
    const high = @max(abs_real, abs_imaginary);
    const low = @min(abs_real, abs_imaginary);
    const step = 192 * low / high;
    const hue: i64 = if (imaginary_part >= 0) blk: {
        if (real_part >= 0) break :blk if (abs_real >= abs_imaginary) step else 384 - step;
        break :blk if (abs_real < abs_imaginary) 384 + step else 768 - step;
    } else if (real_part < 0) blk: {
        break :blk if (abs_real >= abs_imaginary) 768 + step else 1152 - step;
    } else blk: {
        break :blk if (abs_real < abs_imaginary) 1152 + step else 1536 - step;
    };
    return if (hue == 1536) 0 else hue;
}

fn storePixel(pixels: *[MAX_OUTPUT_BYTES]u8, offset: usize, hue: i64, magnitude_16: i64) void {
    const value = 128 + 8 * @mod(magnitude_16, 16);
    const sector = @divTrunc(hue, 256);
    const fraction = @mod(hue, 256);
    const rising: u8 = @intCast(@divTrunc(value * fraction, 255));
    const falling: u8 = @intCast(@divTrunc(value * (255 - fraction), 255));
    const bright: u8 = @intCast(value);
    var red: u8 = 0;
    var green: u8 = 0;
    var blue: u8 = 0;
    switch (sector) {
        0 => { red = bright; green = rising; },
        1 => { red = falling; green = bright; },
        2 => { green = bright; blue = rising; },
        3 => { green = falling; blue = bright; },
        4 => { red = rising; blue = bright; },
        else => { red = bright; blue = falling; },
    }
    pixels[offset] = red;
    pixels[offset + 1] = green;
    pixels[offset + 2] = blue;
}

export fn domain_coloring(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length != 6) return -1;
    const width_value = input[0];
    const height_value = input[1];
    const x_start = input[2];
    const y_start = input[3];
    const x_step = input[4];
    const y_step = input[5];
    if (width_value < 1 or width_value > 16 or height_value < 1 or height_value > 16 or
        x_start < -32 or x_start > 32 or y_start < -32 or y_start > 32 or
        x_step < -8 or x_step > 8 or y_step < -8 or y_step > 8) return -1;
    const x_end = x_start + (width_value - 1) * x_step;
    const y_end = y_start + (height_value - 1) * y_step;
    if (x_end < -32 or x_end > 32 or y_end < -32 or y_end > 32) return -1;

    const width: usize = @intCast(width_value);
    const height: usize = @intCast(height_value);
    const byte_count = 3 * width * height;
    var rendered: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var offset: usize = 0;
    for (0..height) |row| {
        const y_q = y_start + @as(i64, @intCast(row)) * y_step;
        for (0..width) |column| {
            const x_q = x_start + @as(i64, @intCast(column)) * x_step;
            const x_squared = x_q * x_q;
            const y_squared = y_q * y_q;
            storePixel(&rendered, offset, phaseHue(x_squared - y_squared, 2 * x_q * y_q), x_squared + y_squared);
            offset += 3;
        }
    }
    if (output == null or output_capacity < byte_count) return -2;
    for (0..byte_count) |index| output[index] = rendered[index];
    return @intCast(byte_count);
}
