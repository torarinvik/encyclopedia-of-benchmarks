const MAX_VALUES: usize = 256;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_VALUES + 2;
const MAX_OUTPUT_BYTES: usize = 3836;
const I32_MIN_VALUE: i64 = -2147483648;
const I32_MAX_VALUE: i64 = 2147483647;

fn appendDecimal(buffer: *[MAX_OUTPUT_BYTES]u8, position: *usize, value: i64) void {
    var digits: [10]u8 = undefined;
    var count: usize = 0;
    var magnitude: u64 = undefined;
    if (value < 0) {
        buffer[position.*] = '-';
        position.* += 1;
        magnitude = @intCast(-value);
    } else {
        magnitude = @intCast(value);
    }
    while (true) {
        digits[count] = '0' + @as(u8, @intCast(magnitude % 10));
        count += 1;
        magnitude /= 10;
        if (magnitude == 0) break;
    }
    while (count > 0) {
        count -= 1;
        buffer[position.*] = digits[count];
        position.* += 1;
    }
}

export fn print_reverse(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (length > MAX_PARSEABLE_INPUT_LENGTH or length > MAX_VALUES) return -1;
    if (length > 0 and values == null) return -1;
    for (0..length) |index| {
        const value = values.?[index];
        if (value < I32_MIN_VALUE or value > I32_MAX_VALUE) return -1;
    }

    var encoded: [MAX_OUTPUT_BYTES]u8 = undefined;
    var written: usize = 0;
    var remaining = length;
    while (remaining > 0) {
        remaining -= 1;
        if (written != 0) {
            @memcpy(encoded[written .. written + 4], " <- ");
            written += 4;
        }
        appendDecimal(&encoded, &written, values.?[remaining]);
    }

    if (output == null or output_capacity < written) return -2;
    if (written > 0) @memcpy(output.?[0..written], encoded[0..written]);
    return @intCast(written);
}
