/// Apply the pinned JavaScript title-case behavior to bounded ASCII words.
const max_length: usize = 256;

export fn title_case_conversion(input: [*c]const i64, length: usize,
                                output: [*c]u8, output_capacity: usize) i64 {
    if (length == 0 or length > max_length + 1) return -1;
    const declared = input[0];
    if (declared < 0 or declared > max_length or length != @as(usize, @intCast(declared)) + 1) return -1;
    const count: usize = @intCast(declared);
    for (0..count) |index| {
        const value = input[index + 1];
        const letter = (value >= 65 and value <= 90) or (value >= 97 and value <= 122);
        if (!letter and value != 32) return -1;
        if (value == 32 and (index == 0 or index + 1 == count or input[index] == 32)) return -1;
    }
    if (output_capacity < count + 1) return -2;
    var at_word_start = true;
    for (0..count) |index| {
        var value = input[index + 1];
        if (value == 32) {
            at_word_start = true;
        } else if (at_word_start) {
            if (value >= 97 and value <= 122) value -= 32;
            at_word_start = false;
        } else if (value >= 65 and value <= 90) {
            value += 32;
        }
        output[index] = @intCast(value);
    }
    output[count] = 0;
    return declared;
}
