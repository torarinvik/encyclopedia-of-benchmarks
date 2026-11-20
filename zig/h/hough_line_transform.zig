/// Integer-only Hough accumulator with four fixed quantized normals.
const MAX_PARSEABLE_INPUT_LENGTH: usize = 67;
const RHO_COUNT: usize = 29;
const OUTPUT_BYTES: usize = 116;

export fn hough_line_transform(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const height_value = input[0];
    const width_value = input[1];
    if (height_value < 1 or height_value > 8 or width_value < 1 or width_value > 8) return -1;
    const height: usize = @intCast(height_value);
    const width: usize = @intCast(width_value);
    const cells = height * width;
    if (length != 2 + cells) return -1;
    for (0..cells) |index| {
        if (input[index + 2] != 0 and input[index + 2] != 1) return -1;
    }
    if (output == null or output_capacity < OUTPUT_BYTES) return -2;

    var accumulator = [_]u8{0} ** OUTPUT_BYTES;
    for (0..height) |row| {
        for (0..width) |column| {
            if (input[2 + row * width + column] == 0) continue;
            const x: i64 = @intCast(column);
            const y: i64 = @intCast(row);
            const rho = [_]i64{ x, x + y, y, -x + y };
            for (0..4) |angle| {
                const bin = angle * RHO_COUNT + @as(usize, @intCast(rho[angle] + 14));
                accumulator[bin] += 1;
            }
        }
    }
    for (0..OUTPUT_BYTES) |index| output[index] = accumulator[index];
    return @intCast(OUTPUT_BYTES);
}
