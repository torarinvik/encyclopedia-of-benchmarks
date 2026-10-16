const MAX_SIDE_LENGTH: i64 = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1026;

export fn mean_threshold(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    output_capacity: usize,
) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 or input[0] > MAX_SIDE_LENGTH) return -1;

    const side: usize = @intCast(input[0]);
    const pixel_count = side * side;
    if (length != pixel_count + 1) return -1;

    var sum: i64 = 0;
    for (0..pixel_count) |index| {
        const pixel = input[1 + index];
        if (pixel < 0 or pixel > 255) return -1;
        sum += pixel;
    }

    const mean = sum / @as(i64, @intCast(pixel_count));
    if (output_capacity < pixel_count or output == null) return -2;
    for (0..pixel_count) |index| {
        if (input[1 + index] > mean) {
            output[index] = 255;
        } else {
            output[index] = 0;
        }
    }
    return @intCast(pixel_count);
}

