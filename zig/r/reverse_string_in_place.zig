const MAX_LENGTH: usize = 4096;

export fn reverse_string_in_place(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        if (input[index] < 0 or input[index] > 255) return -1;
    }
    if (output_capacity < length) return -2;
    for (0..length) |index| output[index] = @intCast(input[index]);
    var left: usize = 0;
    var right = length;
    while (left < right) {
        right -= 1;
        if (left >= right) break;
        const temporary = output[left];
        output[left] = output[right];
        output[right] = temporary;
        left += 1;
    }
    return @intCast(length);
}
