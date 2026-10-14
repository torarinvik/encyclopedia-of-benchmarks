/// Convert a signed 64-bit integer to canonical negabinary digits.
export fn base_neg2_conversion(input: [*]const i64, length: usize,
                               output: [*]u8, output_capacity: usize) i64 {
    if (length != 1) return -1;
    const original = input[0];
    var width: usize = 0;
    var remaining = original;
    while (true) {
        var quotient = @divTrunc(remaining, -2);
        var digit = @rem(remaining, -2);
        if (digit < 0) { digit += 2; quotient += 1; }
        remaining = quotient;
        width += 1;
        if (remaining == 0) break;
    }
    if (output_capacity < width) return -2;
    var top: usize = 0;
    remaining = original;
    while (true) {
        var quotient = @divTrunc(remaining, -2);
        var digit = @rem(remaining, -2);
        if (digit < 0) { digit += 2; quotient += 1; }
        output[top] = '0' + @as(u8, @intCast(digit));
        top += 1;
        remaining = quotient;
        if (remaining == 0) break;
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
