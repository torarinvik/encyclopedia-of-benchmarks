// Independently written bounded IJG h2v2 adaptation; see package README/LICENSE.
const MAX_WIDTH: usize = 16;
const MAX_HEIGHT: usize = 8;
const MAX_OUTPUT: usize = 512;

pub export fn cbench_consumer_jpeg_h2v2_fancy_upsample(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 5 or length > 131) return -1;
    const width_value = input[0];
    const height_value = input[1];
    if (width_value < 3 or width_value > MAX_WIDTH or height_value < 1 or height_value > MAX_HEIGHT) return -1;
    const width: usize = @intCast(width_value);
    const height: usize = @intCast(height_value);
    const pixels = width * height;
    if (length != 2 + pixels) return -1;
    for (0..pixels) |i| if (input[i + 2] < 0 or input[i + 2] > 255) return -1;
    const output_size = 4 * pixels;
    if (output == null or capacity < output_size) return -2;
    var staged = [_]u8{0} ** MAX_OUTPUT;
    var p: usize = 0;
    for (0..height) |y| {
        for (0..2) |v| {
            const far_y = if (v == 0) (if (y == 0) 0 else y - 1) else (if (y + 1 == height) y else y + 1);
            var sums = [_]i32{0} ** MAX_WIDTH;
            for (0..width) |x| sums[x] = 3 * @as(i32, @intCast(input[2 + y * width + x])) + @as(i32, @intCast(input[2 + far_y * width + x]));
            staged[p] = @intCast((sums[0] * 4 + 8) >> 4); p += 1;
            staged[p] = @intCast((sums[0] * 3 + sums[1] + 7) >> 4); p += 1;
            for (1..width - 1) |x| {
                staged[p] = @intCast((sums[x] * 3 + sums[x - 1] + 8) >> 4); p += 1;
                staged[p] = @intCast((sums[x] * 3 + sums[x + 1] + 7) >> 4); p += 1;
            }
            staged[p] = @intCast((sums[width - 1] * 3 + sums[width - 2] + 8) >> 4); p += 1;
            staged[p] = @intCast((sums[width - 1] * 4 + 7) >> 4); p += 1;
        }
    }
    for (0..output_size) |i| output[i] = staged[i];
    return @intCast(output_size);
}
