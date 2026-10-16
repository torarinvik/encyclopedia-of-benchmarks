const MAX_TEXT_LENGTH: i64 = 256;
const MAX_CHARACTER_LENGTH: i64 = 128;

fn containsCharacter(value: i64, input: [*c]const i64, set_start: usize,
                      set_length: i64) bool {
    if (set_length == -1) return value == 9 or value == 10 or value == 13 or value == 32;
    for (0..@as(usize, @intCast(set_length))) |index| {
        if (input[set_start + index] == value) return true;
    }
    return false;
}

export fn strip(input: [*c]const i64, length: usize,
                output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 386) return -1;
    if (input[0] < 0 or input[0] > MAX_TEXT_LENGTH) return -1;
    const text_length: usize = @intCast(input[0]);
    const set_index = 1 + text_length;
    if (set_index >= length) return -1;
    const set_length = input[set_index];
    var expected_length: usize = undefined;
    if (set_length == -1) {
        expected_length = set_index + 1;
    } else {
        if (set_length < 0 or set_length > MAX_CHARACTER_LENGTH) return -1;
        expected_length = set_index + 1 + @as(usize, @intCast(set_length));
    }
    if (length != expected_length) return -1;
    for (0..text_length) |index| {
        if (input[1 + index] < 0 or input[1 + index] > 127) return -1;
    }
    if (set_length >= 0) {
        for (0..@as(usize, @intCast(set_length))) |index| {
            if (input[set_index + 1 + index] < 0 or input[set_index + 1 + index] > 127) return -1;
        }
    }

    var start: usize = 0;
    var end = text_length;
    while (start < end and containsCharacter(input[1 + start], input, set_index + 1, set_length)) : (start += 1) {}
    while (end > start and containsCharacter(input[end], input, set_index + 1, set_length)) : (end -= 1) {}
    const output_length = end - start;
    if (output_capacity < output_length or (output_length > 0 and output == null)) return -2;
    for (0..output_length) |index| output[index] = @intCast(input[1 + start + index]);
    return @intCast(output_length);
}
