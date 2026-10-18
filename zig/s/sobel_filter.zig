const MIN_SIDE: usize = 3;
const MAX_SIDE: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 258;
const MAX_OUTPUT_ELEMENTS: usize = 512;
const MAX_OUTPUT_BYTES: usize = 4096;
const KERNEL_X = [_]i32{-1, 0, 1, -2, 0, 2, -1, 0, 1};
const KERNEL_Y = [_]i32{1, 2, 1, 0, 0, 0, -1, -2, -1};

fn writeF64Le(output: []u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn sobel_filter(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (values[0] < MIN_SIDE or values[0] > MAX_SIDE) return -1;
    const side: usize = @intCast(values[0]);
    const pixel_count = side * side;
    if (input_length != pixel_count + 1) return -1;

    var image = [_]i32{0} ** (MAX_SIDE * MAX_SIDE);
    for (0..pixel_count) |index| {
        if (values[index + 1] < 0 or values[index + 1] > 255) return -1;
        image[index] = @intCast(values[index + 1]);
    }

    var gradient_x = [_]i32{0} ** (MAX_SIDE * MAX_SIDE);
    var gradient_y = [_]i32{0} ** (MAX_SIDE * MAX_SIDE);
    var max_x: i32 = 0;
    var max_y: i32 = 0;
    for (0..side) |y| {
        for (0..side) |x| {
            var gx: i32 = 0;
            var gy: i32 = 0;
            for (0..3) |ky| {
                var sample_y = y;
                if (ky == 0 and y > 0) sample_y = y - 1;
                if (ky == 2 and y + 1 < side) sample_y = y + 1;
                for (0..3) |kx| {
                    var sample_x = x;
                    if (kx == 0 and x > 0) sample_x = x - 1;
                    if (kx == 2 and x + 1 < side) sample_x = x + 1;
                    const pixel = image[sample_y * side + sample_x];
                    const kernel_index = ky * 3 + kx;
                    gx += pixel * KERNEL_X[kernel_index];
                    gy += pixel * KERNEL_Y[kernel_index];
                }
            }
            gx = @abs(gx);
            gy = @abs(gy);
            const index = y * side + x;
            gradient_x[index] = gx;
            gradient_y[index] = gy;
            max_x = @max(max_x, gx);
            max_y = @max(max_y, gy);
        }
    }
    if (max_x == 0 or max_y == 0) return -1;

    var scaled_x = [_]f64{0} ** (MAX_SIDE * MAX_SIDE);
    var scaled_y = [_]f64{0} ** (MAX_SIDE * MAX_SIDE);
    var magnitude = [_]f64{0} ** (MAX_SIDE * MAX_SIDE);
    var theta = [_]f64{0} ** (MAX_SIDE * MAX_SIDE);
    var max_magnitude: f64 = 0.0;
    for (0..pixel_count) |index| {
        scaled_x[index] = (@as(f64, @floatFromInt(gradient_x[index])) * 255.0) /
            @as(f64, @floatFromInt(max_x));
        scaled_y[index] = (@as(f64, @floatFromInt(gradient_y[index])) * 255.0) /
            @as(f64, @floatFromInt(max_y));
        magnitude[index] = @sqrt((scaled_x[index] * scaled_x[index]) + (scaled_y[index] * scaled_y[index]));
        max_magnitude = @max(max_magnitude, magnitude[index]);
    }
    if (max_magnitude == 0.0) return -1;
    for (0..pixel_count) |index| {
        const normalized = (magnitude[index] * 255.0) / max_magnitude;
        magnitude[index] = @floatFromInt(@as(u8, @intFromFloat(@min(normalized, 255.0))));
        theta[index] = @atan2(scaled_y[index], scaled_x[index]);
    }

    const output_elements = 2 * pixel_count;
    const output_bytes = output_elements * 8;
    if (output_elements > MAX_OUTPUT_ELEMENTS or output_bytes > MAX_OUTPUT_BYTES) return -1;
    const output_ptr = output orelse return -2;
    if (capacity < output_bytes) return -2;
    const output_slice = output_ptr[0..output_bytes];
    for (0..pixel_count) |index| {
        writeF64Le(output_slice, index * 8, magnitude[index]);
        writeF64Le(output_slice, (pixel_count + index) * 8, theta[index]);
    }
    return @intCast(output_elements);
}
