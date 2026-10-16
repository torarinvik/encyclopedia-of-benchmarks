const MAX_DIMENSION: i64 = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1027;

export fn mean_threshold(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    output_capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 or input[0] > MAX_DIMENSION or input[1] < 1 or input[1] > MAX_DIMENSION) return -1;

    const width: usize = @intCast(input[0]);
    const height: usize = @intCast(input[1]);
    const pixel_count = width * height;
    if (length != pixel_count + 2) return -1;

    var sum: i64 = 0;
    for (0..pixel_count) |index| {
        const pixel = input[2 + index];
        if (pixel < 0 or pixel > 255) return -1;
        sum += pixel;
    }

    const mean = sum / @as(i64, @intCast(pixel_count));
    if (output_capacity < pixel_count or output == null) return -2;
    for (0..pixel_count) |index| {
        if (input[2 + index] > mean) {
            output[index] = 255;
        } else {
            output[index] = 0;
        }
    }
    return @intCast(pixel_count);
}

