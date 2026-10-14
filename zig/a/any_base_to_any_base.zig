/// Convert a radix digit array through checked decimal accumulation.
export fn any_base_to_any_base(input: [*]const i64, length: usize,
                               output: [*]u8, output_capacity: usize) i64 {
    if (length < 3 or length > 65) return -1;
    const source_base = input[0];
    const target_base = input[1];
    if (source_base < 2 or source_base > 36 or target_base < 2 or target_base > 36) return -1;
    var value: i64 = 0;
    for (2..length) |index| {
        const digit = input[index];
        if (digit < 0 or digit >= source_base) return -1;
        if (value > @divTrunc(9223372036854775807 - digit, source_base)) return -1;
        value = value * source_base + digit;
    }
    var width: usize = 1;
    var remaining = value;
    while (remaining >= target_base) : (remaining = @divTrunc(remaining, target_base)) width += 1;
    if (output_capacity < width) return -2;
    var top: usize = 0;
    remaining = value;
    if (remaining == 0) { output[top] = '0'; top += 1; }
    while (remaining > 0) {
        const digit = @rem(remaining, target_base);
        output[top] = if (digit < 10) '0' + @as(u8, @intCast(digit))
            else 'A' + @as(u8, @intCast(digit - 10));
        top += 1;
        remaining = @divTrunc(remaining, target_base);
    }
    var left: usize = 0;
    var right = top - 1;
    while (left < right) {
        const temporary = output[left];
        output[left] = output[right];
        output[right] = temporary;
        left += 1; right -= 1;
    }
    return @intCast(top);
}
