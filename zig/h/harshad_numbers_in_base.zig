const MAX_LIMIT: i64 = 10000;

fn digitSum(number_value: i64, base: i64) i64 {
    var remaining = number_value;
    var sum: i64 = 0;
    while (remaining > 0) {
        sum += @mod(remaining, base);
        remaining = @divTrunc(remaining, base);
    }
    return sum;
}

fn baseLength(number_value: i64, base: i64) usize {
    var remaining = number_value;
    var length: usize = 0;
    while (remaining > 0) {
        length += 1;
        remaining = @divTrunc(remaining, base);
    }
    return length;
}

fn requiredLength(limit: i64, base: i64) usize {
    var length: usize = 0;
    var number: i64 = 1;
    while (number < limit) : (number += 1) {
        if (@mod(number, digitSum(number, base)) == 0) {
            length += baseLength(number, base) + 1;
        }
    }
    return length;
}

fn digitByte(digit: i64) u8 {
    return @intCast(if (digit < 10) '0' + digit else 'A' + digit - 10);
}

fn appendBase(number_value: i64, base: i64, output: [*c]u8, position_value: usize) usize {
    var digits: [64]u8 = undefined;
    var count: usize = 0;
    var remaining = number_value;
    while (remaining > 0) {
        digits[count] = digitByte(@mod(remaining, base));
        count += 1;
        remaining = @divTrunc(remaining, base);
    }
    var position = position_value;
    while (count > 0) {
        count -= 1;
        output[position] = digits[count];
        position += 1;
    }
    return position;
}

/// Encode each source string as uppercase base digits followed by a NUL byte.
export fn harshad_numbers_in_base(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 2) return -1;
    const limit = values[0];
    const base = values[1];
    if (limit > MAX_LIMIT or base < 2 or base > 36) return -1;
    const required = requiredLength(limit, base);
    if (output == null or output_capacity < required) return -2;
    var position: usize = 0;
    var number: i64 = 1;
    while (number < limit) : (number += 1) {
        if (@mod(number, digitSum(number, base)) == 0) {
            position = appendBase(number, base, output, position);
            output[position] = 0;
            position += 1;
        }
    }
    return @intCast(position);
}
