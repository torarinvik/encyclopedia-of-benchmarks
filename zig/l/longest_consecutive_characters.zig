export fn longest_consecutive_characters(values: [*]const i64, length: usize,
                                         output: [*]u8, capacity: usize) i64 {
    if (length < 1 or length > 257) return -1;
    const count_value = values[0];
    if (count_value < 1 or count_value > 256 or length != @as(usize, @intCast(count_value)) + 1) return -1;
    const count: usize = @intCast(count_value);
    for (0..count) |index| {
        if (values[index + 1] < 0 or values[index + 1] > 127) return -1;
    }
    if (capacity < 3) return -2;

    var best_character = values[1];
    var best_length: usize = 1;
    var current_length: usize = 1;
    for (1..count) |index| {
        if (values[index + 1] == values[index]) {
            current_length += 1;
            if (current_length > best_length) {
                best_length = current_length;
                best_character = values[index + 1];
            }
        } else {
            current_length = 1;
        }
    }
    output[0] = @intCast(best_character);
    output[1] = @intCast(best_length & 255);
    output[2] = @intCast(best_length >> 8);
    return 3;
}
