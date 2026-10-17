const MAX_PIXELS: usize = 256;

noinline fn roundedAdd(left: f64, right: f64) f64 { return left + right; }
noinline fn roundedSubtract(left: f64, right: f64) f64 { return left - right; }
noinline fn roundedMultiply(left: f64, right: f64) f64 { return left * right; }
noinline fn roundedDivide(left: f64, right: f64) f64 { return left / right; }

export fn mandelbrot(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (length != 6) return -1;
    const width_value = values[0];
    const height_value = values[1];
    const center_x_q = values[2];
    const center_y_q = values[3];
    const figure_width_q = values[4];
    const max_step_value = values[5];
    if (width_value < 1 or width_value > 16 or height_value < 1 or height_value > 16 or
        center_x_q < -64 or center_x_q > 64 or center_y_q < -64 or center_y_q > 64 or
        figure_width_q < 1 or figure_width_q > 64 or max_step_value < 2 or max_step_value > 64)
        return -1;
    const width: usize = @intCast(width_value);
    const height: usize = @intCast(height_value);
    const max_step: usize = @intCast(max_step_value);
    const pixel_count = width * height;
    if (pixel_count > MAX_PIXELS) return -1;
    const out = output orelse return -2;
    if (capacity < pixel_count) return -2;

    const center_x = @as(f64, @floatFromInt(center_x_q)) / 16.0;
    const center_y = @as(f64, @floatFromInt(center_y_q)) / 16.0;
    const figure_width = @as(f64, @floatFromInt(figure_width_q)) / 16.0;
    const figure_height = roundedMultiply(roundedDivide(figure_width, @floatFromInt(width)), @floatFromInt(height));
    var offset: usize = 0;
    for (0..width) |image_x| {
        const x_position = roundedSubtract(roundedDivide(@floatFromInt(image_x), @floatFromInt(width)), 0.5);
        const figure_x = roundedAdd(center_x, roundedMultiply(x_position, figure_width));
        for (0..height) |image_y| {
            const y_position = roundedSubtract(roundedDivide(@floatFromInt(image_y), @floatFromInt(height)), 0.5);
            const figure_y = roundedAdd(center_y, roundedMultiply(y_position, figure_height));
            var a = figure_x;
            var b = figure_y;
            var current_step: usize = 0;
            for (0..max_step) |step| {
                current_step = step;
                const a_new = roundedAdd(roundedSubtract(roundedMultiply(a, a), roundedMultiply(b, b)), figure_x);
                b = roundedAdd(roundedMultiply(roundedMultiply(2.0, a), b), figure_y);
                a = a_new;
                if (roundedAdd(roundedMultiply(a, a), roundedMultiply(b, b)) > 4.0) break;
            }
            const normalized_distance = roundedDivide(@floatFromInt(current_step), @floatFromInt(max_step - 1));
            out[offset] = if (normalized_distance >= 1.0) 0 else 255;
            offset += 1;
        }
    }
    return @intCast(pixel_count);
}
