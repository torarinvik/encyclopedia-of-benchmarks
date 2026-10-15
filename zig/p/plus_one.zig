export fn plus_one(digits: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length > 256) return -1;
    var all_nines = true;
    for (0..length) |index| {
        const digit = digits[index];
        if (digit < 0 or digit > 9) return -1;
        if (digit != 9) all_nines = false;
    }
    if (length > 1 and digits[0] == 0) return -1;
    const output_length = if (length == 0 or all_nines) length + 1 else length;
    if (output_capacity < output_length) return -2;
    if (length == 0 or all_nines) {
        output[0] = '1';
        for (1..output_length) |index| output[index] = '0';
        return @intCast(output_length);
    }
    for (0..length) |index| output[index] = '0' + @as(u8, @intCast(digits[index]));
    var index = length;
    while (index > 0) {
        index -= 1;
        if (digits[index] == 9) output[index] = '0'
        else {
            output[index] += 1;
            break;
        }
    }
    return @intCast(output_length);
}
