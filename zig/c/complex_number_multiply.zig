const Complex = struct { real: i64, imaginary: i64 };

fn parseComponent(bytes: []const i64) ?i64 {
    var start: usize = 0;
    var negative = false;
    if (bytes.len > 0 and bytes[0] == 45) { negative = true; start = 1; }
    if (start == bytes.len) return null;
    var magnitude: i64 = 0;
    for (bytes[start..]) |byte| {
        if (byte < 48 or byte > 57) return null;
        const digit = byte - 48;
        if (magnitude > (32767 - digit) / 10) return null;
        magnitude = magnitude * 10 + digit;
    }
    return if (negative) -magnitude else magnitude;
}

fn parseComplex(bytes: []const i64) ?Complex {
    if (bytes.len < 4 or bytes.len > 64 or bytes[bytes.len - 1] != 105) return null;
    var separator: ?usize = null;
    for (bytes[0 .. bytes.len - 1], 0..) |byte, index| {
        if (byte == 43) {
            if (separator != null) return null;
            separator = index;
        }
    }
    const split = separator orelse return null;
    const real = parseComponent(bytes[0..split]) orelse return null;
    const imaginary = parseComponent(bytes[split + 1 .. bytes.len - 1]) orelse return null;
    return .{ .real = real, .imaginary = imaginary };
}

fn decimalLength(value: i64) usize {
    var length: usize = if (value < 0) 1 else 0;
    var magnitude = if (value < 0) -value else value;
    if (magnitude == 0) return length + 1;
    while (magnitude > 0) : (magnitude /= 10) length += 1;
    return length;
}

fn appendDecimal(output: []u8, write_index: *usize, value: i64) void {
    var magnitude = value;
    if (magnitude < 0) { output[write_index.*] = 45; write_index.* += 1; magnitude = -magnitude; }
    const start = write_index.*;
    if (magnitude == 0) { output[write_index.*] = 48; write_index.* += 1; return; }
    while (magnitude > 0) : (magnitude /= 10) {
        output[write_index.*] = @intCast(48 + @mod(magnitude, 10));
        write_index.* += 1;
    }
    var left = start;
    var right = write_index.* - 1;
    while (left < right) : ({ left += 1; right -= 1; }) {
        const temporary = output[left];
        output[left] = output[right];
        output[right] = temporary;
    }
}

export fn complex_number_multiply(input: ?[*]const i64, length: usize,
                                  output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 130) return -1;
    const values = input.?[0..length];
    const raw_left_length = values[0];
    const raw_right_length = values[1];
    if (raw_left_length < 4 or raw_left_length > 64 or raw_right_length < 4 or raw_right_length > 64) return -1;
    const left_length: usize = @intCast(raw_left_length);
    const right_length: usize = @intCast(raw_right_length);
    if (length != 2 + left_length + right_length) return -1;
    const left_bytes = values[2 .. 2 + left_length];
    const right_bytes = values[2 + left_length ..];
    for (values[2..]) |byte| if (byte < 0 or byte > 127) return -1;
    const left = parseComplex(left_bytes) orelse return -1;
    const right = parseComplex(right_bytes) orelse return -1;

    const real = left.real * right.real - left.imaginary * right.imaginary;
    const imaginary = left.real * right.imaginary + left.imaginary * right.real;
    const needed = decimalLength(real) + decimalLength(imaginary) + 2;
    if (output == null or capacity < needed) return -2;
    const result = output.?[0..needed];
    var written: usize = 0;
    appendDecimal(result, &written, real);
    result[written] = 43;
    written += 1;
    appendDecimal(result, &written, imaginary);
    result[written] = 105;
    written += 1;
    return @intCast(written);
}
