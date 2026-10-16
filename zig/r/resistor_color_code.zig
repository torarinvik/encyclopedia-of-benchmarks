const MAX_TEXT_LENGTH: i64 = 41;
const MAX_PARSEABLE_LENGTH: usize = 43;
const COLOR_NAMES = [_][]const u8{
    "Black", "Brown", "Red", "Orange", "Yellow", "Green",
    "Blue", "Violet", "Grey", "White", "Gold", "Silver",
};
const TOLERANCE_TEXT = [_][]const u8{"", "1", "2", "0.05", "0.02", "0.5", "0.25", "0.1", "0.01", "", "5", "10"};
const TEMPERATURE_VALUES = [_]u64{250, 100, 50, 15, 25, 20, 10, 5, 1};

fn colorCode(values: [*c]const i64, start: usize, end: usize) ?usize {
    for (COLOR_NAMES, 0..) |name, color| {
        if (name.len != end - start) continue;
        var same = true;
        for (name, 0..) |byte, i| if (values[start + i + 1] != @as(i64, byte)) { same = false; };
        if (same) return color;
    }
    return null;
}

fn appendByte(buffer: *[64]u8, length: *usize, byte: u8) void {
    buffer[length.*] = byte;
    length.* += 1;
}

fn appendText(buffer: *[64]u8, length: *usize, text: []const u8) void {
    for (text) |byte| appendByte(buffer, length, byte);
}

fn appendUint(buffer: *[64]u8, length: *usize, value: u64) void {
    var digits: [24]u8 = undefined;
    var count: usize = 0;
    var remaining = value;
    while (true) {
        digits[count] = @as(u8, '0') + @as(u8, @intCast(remaining % 10));
        count += 1;
        remaining /= 10;
        if (remaining == 0) break;
    }
    while (count > 0) {
        count -= 1;
        appendByte(buffer, length, digits[count]);
    }
}

export fn resistor_color_code(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 2 or length > MAX_PARSEABLE_LENGTH) return -1;
    const text_length = values[0];
    if (text_length < 1 or text_length > MAX_TEXT_LENGTH or length != @as(usize, @intCast(text_length + 1))) return -1;
    for (0..@as(usize, @intCast(text_length))) |i| if (values[i + 1] < 0 or values[i + 1] > 127) return -1;

    var colors: [6]usize = undefined;
    var color_count: usize = 0;
    var start: usize = 0;
    for (0..@as(usize, @intCast(text_length)) + 1) |i| {
        if (i == @as(usize, @intCast(text_length)) or values[i + 1] == ',') {
            if (color_count == colors.len or i == start) return -1;
            const color = colorCode(values, start, i) orelse return -1;
            colors[color_count] = color;
            color_count += 1;
            start = i + 1;
        }
    }
    if (color_count < 3 or color_count > 6) return -1;

    const significant_count: usize = if (color_count <= 4) 2 else 3;
    var significant: u64 = 0;
    for (0..significant_count) |i| {
        if (colors[i] > 9) return -1;
        significant = significant * 10 + @as(u64, @intCast(colors[i]));
    }
    const multiplier = colors[significant_count];
    const tolerance_color: ?usize = if (color_count >= 4) colors[significant_count + 1] else null;
    const temperature_color: ?usize = if (color_count == 6) colors[5] else null;
    if (tolerance_color) |color| {
        if (!((color >= 1 and color <= 8) or color == 10 or color == 11)) return -1;
    }
    if (temperature_color) |color| {
        if (color > 8) return -1;
    }

    var buffer: [64]u8 = undefined;
    var out_length: usize = 0;
    if (multiplier <= 9) {
        var resistance = significant;
        for (0..multiplier) |_| resistance *= 10;
        appendUint(&buffer, &out_length, resistance);
    } else if (multiplier == 10) {
        appendUint(&buffer, &out_length, significant / 10);
        appendByte(&buffer, &out_length, '.');
        appendByte(&buffer, &out_length, @as(u8, '0') + @as(u8, @intCast(significant % 10)));
    } else {
        const whole = significant / 100;
        const fraction = significant % 100;
        appendUint(&buffer, &out_length, whole);
        appendByte(&buffer, &out_length, '.');
        if (fraction == 0) appendByte(&buffer, &out_length, '0')
        else if (fraction % 10 == 0) appendByte(&buffer, &out_length, @as(u8, '0') + @as(u8, @intCast(fraction / 10)))
        else {
            appendByte(&buffer, &out_length, @as(u8, '0') + @as(u8, @intCast(fraction / 10)));
            appendByte(&buffer, &out_length, @as(u8, '0') + @as(u8, @intCast(fraction % 10)));
        }
    }
    appendText(&buffer, &out_length, "\xCE\xA9 \xC2\xB1");
    if (tolerance_color) |color| appendText(&buffer, &out_length, TOLERANCE_TEXT[color]) else appendText(&buffer, &out_length, "20");
    appendText(&buffer, &out_length, "% ");
    if (temperature_color) |color| {
        appendUint(&buffer, &out_length, TEMPERATURE_VALUES[color]);
        appendText(&buffer, &out_length, " ppm/K");
    }
    if (capacity < out_length or (output == null and out_length > 0)) return -2;
    for (0..out_length) |i| output[i] = buffer[i];
    return @intCast(out_length);
}
