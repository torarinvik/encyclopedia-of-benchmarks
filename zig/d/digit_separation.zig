/// Separate signed decimal digits; direction 0 is reverse and 1 is forward.
export fn digit_separation(input: [*]const i64, input_length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (input_length != 2 or (input[1] != 0 and input[1] != 1)) return -1;
    var remaining = input[0];
    var digits: [20]u8 = undefined;
    var count: usize = 0;
    if (remaining == 0) {
        digits[0] = 0;
        count = 1;
    }
    while (remaining != 0) {
        const remainder = @rem(remaining, 10);
        digits[count] = @intCast(if (remainder < 0) -remainder else remainder);
        count += 1;
        remaining = @divTrunc(remaining, 10);
    }
    if (output_capacity < count) return -2;
    for (0..count) |index| {
        const source = if (input[1] == 0) index else count - index - 1;
        output[index] = digits[source];
    }
    return @intCast(count);
}
