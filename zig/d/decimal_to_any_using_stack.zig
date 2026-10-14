/// Convert a nonnegative signed 64-bit value with a LIFO digit stack.
export fn decimal_to_any_using_stack(input: [*]const i64, length: usize,
                                     output: [*]u8, output_capacity: usize) i64 {
    if (length != 2) return -1;
    const value = input[0];
    const base = input[1];
    if (value < 0 or base < 2 or base > 16) return -1;
    var width: usize = 1;
    var remaining = value;
    while (remaining >= base) : (remaining = @divTrunc(remaining, base)) width += 1;
    if (output_capacity < width) return -2;
    var top: usize = 0;
    remaining = value;
    if (remaining == 0) { output[top] = '0'; top += 1; }
    while (remaining > 0) {
        const digit = @rem(remaining, base);
        output[top] = if (digit < 10) '0' + @as(u8, @intCast(digit))
            else 'A' + @as(u8, @intCast(digit - 10));
        top += 1;
        remaining = @divTrunc(remaining, base);
    }
    var left: usize = 0;
    var right = top - 1;
    while (left < right) {
        const temporary = output[left];
        output[left] = output[right];
        output[right] = temporary;
        left += 1;
        right -= 1;
    }
    return @intCast(top);
}
