const MAX_APPEND_COUNT: i64 = 4096;
const MAX_TEXT_BYTES: usize = 24576;

export fn shootout_strcat(append_count: i64, output_opt: ?[*]u8,
    output_capacity: usize) i64 {
    if (append_count < 0 or append_count > MAX_APPEND_COUNT) return -1;

    var text: [MAX_TEXT_BYTES + 1]u8 = undefined;
    var length: usize = 0;
    var buffer_capacity: usize = 32;
    var append: i64 = 0;
    while (append < append_count) : (append += 1) {
        if (buffer_capacity - length < 7) buffer_capacity *= 2;
        text[length] = 104;
        text[length + 1] = 101;
        text[length + 2] = 108;
        text[length + 3] = 108;
        text[length + 4] = 111;
        text[length + 5] = 10;
        length += 6;
        text[length] = 0;
    }

    var staged: [6]u8 = undefined;
    var reversed_digits: [5]u8 = undefined;
    var digit_count: usize = 0;
    var value = length;
    while (true) {
        reversed_digits[digit_count] = @intCast(48 + value % 10);
        digit_count += 1;
        value /= 10;
        if (value == 0) break;
    }
    var used: usize = 0;
    while (digit_count > 0) {
        digit_count -= 1;
        staged[used] = reversed_digits[digit_count];
        used += 1;
    }
    staged[used] = 10;
    used += 1;

    if (output_opt == null or output_capacity < used) return -2;
    const output = output_opt.?;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
