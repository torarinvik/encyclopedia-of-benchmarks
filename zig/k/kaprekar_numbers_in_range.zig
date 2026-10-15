/// Enumerate Kaprekar numbers as decimal NUL-terminated values.
const MAX_END: i64 = 100000;

fn isKaprekar(number: i64) bool {
    if (number == 0 or number == 1) return true;
    const square = number * number;
    var split: i64 = 1;
    var remaining = number;
    while (remaining > 0) { split *= 10; remaining = @divTrunc(remaining, 10); }
    const right = @mod(square, split);
    return right != 0 and @divTrunc(square, split) + right == number;
}

fn decimalLength(number_value: i64) usize {
    var number = number_value;
    var length: usize = 1;
    while (number >= 10) { number = @divTrunc(number, 10); length += 1; }
    return length;
}

fn requiredLength(start: i64, ending: i64) usize {
    var bytes: usize = 0;
    var number = start;
    while (number <= ending) : (number += 1) {
        if (isKaprekar(number)) bytes += decimalLength(number) + 1;
    }
    return bytes;
}

fn appendDecimal(number_value: i64, output: [*c]u8, position_value: usize) usize {
    var digits: [20]u8 = undefined;
    var count: usize = 0;
    var number = number_value;
    while (number > 0) { digits[count] = @intCast('0' + @mod(number, 10)); count += 1; number = @divTrunc(number, 10); }
    if (count == 0) { digits[0] = '0'; count = 1; }
    var position = position_value;
    while (count > 0) { count -= 1; output[position] = digits[count]; position += 1; }
    return position;
}

/// Return output bytes, -1 for invalid input, or -2 for insufficient capacity.
export fn kaprekar_numbers_in_range(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 2) return -1;
    const start = values[0];
    const ending = values[1];
    if (start < 0 or start > ending or ending > MAX_END) return -1;
    const required = requiredLength(start, ending);
    if (output == null or output_capacity < required) return -2;
    var position: usize = 0;
    var number = start;
    while (number <= ending) : (number += 1) {
        if (!isKaprekar(number)) continue;
        position = appendDecimal(number, output, position);
        output[position] = 0;
        position += 1;
    }
    return @intCast(position);
}
