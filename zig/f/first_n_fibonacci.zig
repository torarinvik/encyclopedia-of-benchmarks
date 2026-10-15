/// Emit the first n Fibonacci terms as decimal NUL-terminated values.
const MIN_COUNT: i64 = 3;
const MAX_COUNT: i64 = 79;

fn decimalLength(number_value: i64) usize {
    var number = number_value;
    var length: usize = 1;
    while (number >= 10) { number = @divTrunc(number, 10); length += 1; }
    return length;
}

fn requiredLength(count: i64) usize {
    var bytes: usize = 0;
    var previous: i64 = 0;
    var current: i64 = 1;
    var index: i64 = 0;
    while (index < count) : (index += 1) {
        var value: i64 = 0;
        if (index == 0) value = 0 else if (index == 1) value = 1 else {
            value = previous + current;
            previous = current;
            current = value;
        }
        bytes += decimalLength(value) + 1;
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
export fn first_n_fibonacci(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 1) return -1;
    const count = values[0];
    if (count < MIN_COUNT or count > MAX_COUNT) return -1;
    const required = requiredLength(count);
    if (output == null or output_capacity < required) return -2;
    var previous: i64 = 0;
    var current: i64 = 1;
    var index: i64 = 0;
    var position: usize = 0;
    while (index < count) : (index += 1) {
        var value: i64 = 0;
        if (index == 0) value = 0 else if (index == 1) value = 1 else {
            value = previous + current;
            previous = current;
            current = value;
        }
        position = appendDecimal(value, output, position);
        output[position] = 0;
        position += 1;
    }
    return @intCast(position);
}
