const MAX_SIDE: usize = 32;
const MAX_PIXELS: usize = MAX_SIDE * MAX_SIDE;

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn bilateral_filter(values: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 5 or length > 5 + MAX_PIXELS) return -1;
    const height_value = values[0];
    const width_value = values[1];
    const kernel_value = values[2];
    const spatial_q = values[3];
    const intensity_q = values[4];
    if (height_value < 1 or height_value > MAX_SIDE or width_value < 1 or width_value > MAX_SIDE or
        (kernel_value != 1 and kernel_value != 3 and kernel_value != 5 and kernel_value != 7) or
        spatial_q < 1 or spatial_q > 1_000_000 or intensity_q < 1 or intensity_q > 1_000_000) return -1;
    const height: usize = @intCast(height_value);
    const width: usize = @intCast(width_value);
    const pixels = height * width;
    if (length != 5 + pixels) return -1;
    for (5..length) |index| if (values[index] < 0 or values[index] > 1_000_000) return -1;
    const required = pixels * 8;
    if (output == null or output_capacity < required) return -2;

    const radius: usize = @intCast(@divTrunc(kernel_value, 2));
    const kernel_size: usize = @intCast(kernel_value);
    const row_end = if (height >= kernel_size) height - radius else radius;
    const column_end = if (width >= kernel_size) width - radius else radius;
    const spatial_variance = @as(f64, @floatFromInt(spatial_q)) / 1_000_000.0;
    const intensity_variance = @as(f64, @floatFromInt(intensity_q)) / 1_000_000.0;
    var filtered: [MAX_PIXELS]i64 = @splat(0);
    for (radius..row_end) |row| {
        for (radius..column_end) |column| {
            const center = @as(f64, @floatFromInt(values[5 + row * width + column])) / 1_000_000.0;
            var weighted_sum: f64 = 0.0;
            var weight_sum: f64 = 0.0;
            var dy: i64 = -@as(i64, @intCast(radius));
            while (dy <= @as(i64, @intCast(radius))) : (dy += 1) {
                var dx: i64 = -@as(i64, @intCast(radius));
                while (dx <= @as(i64, @intCast(radius))) : (dx += 1) {
                    const sample_row: usize = @intCast(@as(i64, @intCast(row)) + dy);
                    const sample_column: usize = @intCast(@as(i64, @intCast(column)) + dx);
                    const sample = @as(f64, @floatFromInt(values[5 + sample_row * width + sample_column])) / 1_000_000.0;
                    const dist = @as(f64, @floatFromInt(dx * dx + dy * dy));
                    const difference = sample - center;
                    var weight = @exp(-dist / (2.0 * spatial_variance));
                    weight *= @exp(-(difference * difference) / (2.0 * intensity_variance));
                    weighted_sum += sample * weight;
                    weight_sum += weight;
                }
            }
            filtered[row * width + column] = @intFromFloat(weighted_sum / weight_sum * 1_000_000.0 + 0.5);
        }
    }
    for (0..pixels) |index| writeI64Le(output, index * 8, filtered[index]);
    return @intCast(required);
}
