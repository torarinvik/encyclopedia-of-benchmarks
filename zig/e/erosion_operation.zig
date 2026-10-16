const MAX_INPUT_LENGTH: usize = 38;

export fn erosion_operation(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    const height_arg = values[0];
    const width_arg = values[1];
    if (height_arg < 1 or height_arg > 6 or width_arg < 1 or width_arg > 6) return -1;
    const height: usize = @intCast(height_arg);
    const width: usize = @intCast(width_arg);
    if (length != 2 + height * width) return -1;
    for (values[2 .. 2 + height * width]) |value| if (value != 0 and value != 1) return -1;
    if (height < 3 or width < 3) return 0;
    var result: i64 = 0;
    for (1..height - 1) |row| {
        for (1..width - 1) |column| {
            const at = 2 + row * width + column;
            if (values[at] == 1 and values[at - width] == 1 and values[at + width] == 1 and values[at - 1] == 1 and values[at + 1] == 1) {
                result |= @as(i64, 1) << @intCast(row * width + column);
            }
        }
    }
    return result;
}
