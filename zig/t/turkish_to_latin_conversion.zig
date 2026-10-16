const Decoded = struct { codepoint: u32, width: usize };

fn continuation(byte: u8) bool { return byte >= 0x80 and byte <= 0xBF; }

fn decodeUtf8(bytes: []const u8, index: usize) ?Decoded {
    const first = bytes[index];
    if (first <= 0x7F) return .{ .codepoint = first, .width = 1 };
    if (first >= 0xC2 and first <= 0xDF) {
        if (index + 1 >= bytes.len or !continuation(bytes[index + 1])) return null;
        return .{ .codepoint = (@as(u32, first & 0x1F) << 6) | (bytes[index + 1] & 0x3F), .width = 2 };
    }
    if (first >= 0xE0 and first <= 0xEF) {
        if (index + 2 >= bytes.len) return null;
        const second = bytes[index + 1];
        const third = bytes[index + 2];
        if (!continuation(second) or !continuation(third) or
            (first == 0xE0 and second < 0xA0) or (first == 0xED and second >= 0xA0)) return null;
        return .{ .codepoint = (@as(u32, first & 0x0F) << 12) |
            (@as(u32, second & 0x3F) << 6) | (third & 0x3F), .width = 3 };
    }
    if (first >= 0xF0 and first <= 0xF4) {
        if (index + 3 >= bytes.len) return null;
        const second = bytes[index + 1];
        const third = bytes[index + 2];
        const fourth = bytes[index + 3];
        if (!continuation(second) or !continuation(third) or !continuation(fourth) or
            (first == 0xF0 and second < 0x90) or (first == 0xF4 and second > 0x8F)) return null;
        return .{ .codepoint = (@as(u32, first & 0x07) << 18) |
            (@as(u32, second & 0x3F) << 12) | (@as(u32, third & 0x3F) << 6) | (fourth & 0x3F), .width = 4 };
    }
    return null;
}

fn mapTurkish(codepoint: u32) ?u8 {
    return switch (codepoint) {
        0x0131 => 'i', 0x0130 => 'I',
        0x00FC => 'u', 0x00DC => 'U',
        0x00F6 => 'o', 0x00D6 => 'O',
        0x015F => 's', 0x015E => 'S',
        0x00E7 => 'c', 0x00C7 => 'C',
        0x011F => 'g', 0x011E => 'G',
        else => null,
    };
}

pub export fn turkish_to_latin_conversion(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    const max_text_bytes: usize = 1024;
    if (input == null or length < 1 or length > max_text_bytes + 1) return -1;
    if (input[0] < 0 or input[0] > max_text_bytes or length != @as(usize, @intCast(input[0])) + 1) return -1;
    const text_length: usize = @intCast(input[0]);
    var bytes: [max_text_bytes]u8 = @splat(0);
    for (0..text_length) |index| {
        const value = input[index + 1];
        if (value < 0 or value > 255) return -1;
        bytes[index] = @intCast(value);
    }
    var result_length: usize = 0;
    var index: usize = 0;
    while (index < text_length) {
        const decoded = decodeUtf8(bytes[0..text_length], index) orelse return -1;
        result_length += if (mapTurkish(decoded.codepoint) != null) 1 else decoded.width;
        index += decoded.width;
    }
    if (result_length > output_capacity or (result_length > 0 and output == null)) return -2;
    var written: usize = 0;
    index = 0;
    while (index < text_length) {
        const decoded = decodeUtf8(bytes[0..text_length], index).?;
        if (mapTurkish(decoded.codepoint)) |mapped| {
            output[written] = mapped;
            written += 1;
        } else {
            for (0..decoded.width) |byte| output[written + byte] = bytes[index + byte];
            written += decoded.width;
        }
        index += decoded.width;
    }
    return @intCast(result_length);
}
