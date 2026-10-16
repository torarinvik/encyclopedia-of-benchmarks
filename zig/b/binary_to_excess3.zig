/// Parse an ASCII base-2 integer, add three, and format with minimum width four.
const max_text_length: usize = 128;
const max_magnitude: i64 = 4_611_686_018_427_387_904;

fn isAsciiSpace(value: i64) bool {
    return value == 32 or (value >= 9 and value <= 13);
}

fn isBinaryDigit(value: i64) bool {
    return value == '0' or value == '1';
}

export fn binary_to_excess3(values: [*c]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (values == null or length == 0 or length > max_text_length) return -1;
    var start: usize = 0;
    var end = length;
    while (start < end and isAsciiSpace(values[start])) : (start += 1) {}
    while (end > start and isAsciiSpace(values[end - 1])) : (end -= 1) {}
    if (start == end) return -1;

    var negative = false;
    if (values[start] == '+' or values[start] == '-') {
        negative = values[start] == '-';
        start += 1;
        if (start == end) return -1;
    }
    const prefixed = end - start >= 2 and values[start] == '0' and
        (values[start + 1] == 'b' or values[start + 1] == 'B');
    if (prefixed) start += 2;
    if (start == end) return -1;

    const digit_start = start;
    var allow_prefix_underscore = prefixed;
    var have_digit = false;
    var last_was_digit = false;
    var magnitude: i64 = 0;
    for (start..end) |index| {
        const value = values[index];
        if (isBinaryDigit(value)) {
            const digit = value - '0';
            if (magnitude > @divTrunc(max_magnitude - digit, 2)) return -1;
            magnitude = magnitude * 2 + digit;
            have_digit = true;
            last_was_digit = true;
            allow_prefix_underscore = false;
        } else if (value == '_') {
            if (last_was_digit and index + 1 < end and isBinaryDigit(values[index + 1])) {
                last_was_digit = false;
            } else if (allow_prefix_underscore and !have_digit and index == digit_start and
                index + 1 < end and isBinaryDigit(values[index + 1])) {
                allow_prefix_underscore = false;
            } else {
                return -1;
            }
        } else {
            return -1;
        }
    }
    if (!have_digit or !last_was_digit) return -1;

    const result: i64 = (if (negative) -magnitude else magnitude) + 3;
    const result_is_negative = result < 0;
    var remaining: i64 = if (result_is_negative) -result else result;
    var reversed: [64]u8 = undefined;
    var digit_count: usize = 0;
    while (true) {
        reversed[digit_count] = '0' + @as(u8, @intCast(@rem(remaining, 2)));
        digit_count += 1;
        remaining = @divTrunc(remaining, 2);
        if (remaining == 0) break;
    }

    const sign_length: usize = if (result_is_negative) 1 else 0;
    const output_length = @max(sign_length + digit_count, 4);
    if (output_capacity < output_length) return -2;
    var position: usize = 0;
    if (result_is_negative) {
        output[position] = '-';
        position += 1;
    }
    const digit_width = output_length - sign_length;
    for (digit_count..digit_width) |_| {
        output[position] = '0';
        position += 1;
    }
    for (0..digit_count) |offset| {
        output[position] = reversed[digit_count - 1 - offset];
        position += 1;
    }
    return @intCast(output_length);
}
