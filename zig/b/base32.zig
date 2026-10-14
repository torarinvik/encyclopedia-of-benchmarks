/// Encode and decode bytes with the RFC 4648 Base32 alphabet.
fn base32Value(byte: i64) i64 {
    if (byte >= 'A' and byte <= 'Z') return byte - 'A';
    if (byte >= '2' and byte <= '7') return byte - '2' + 26;
    return -1;
}

export fn base32(input: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > 66) return -1;
    const mode = input[0];
    if (mode == 0) {
        const count = length - 1;
        for (1..length) |i| if (input[i] < 0 or input[i] > 255) return -1;
        const output_length = if (count == 0) 0 else ((count + 4) / 5) * 8;
        if (output_capacity < output_length) return -2;
        var written: usize = 0;
        var start: usize = 0;
        while (start < count) : (start += 5) {
            const bytes: usize = @min(count - start, @as(usize, 5));
            const bits: usize = bytes * @as(usize, 8);
            const symbols: usize = (bits + 4) / 5;
            for (0..@as(usize, 8)) |symbol| {
                if (symbol >= symbols) {
                    output[written] = '=';
                } else {
                    var value: u8 = 0;
                    for (symbol * 5..symbol * 5 + 5) |bit| {
                        value <<= 1;
                        if (bit < bits) {
                            const byte: u8 = @intCast(input[1 + start + bit / 8]);
                            value |= (byte >> @intCast(7 - bit % 8)) & 1;
                        }
                    }
                    output[written] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"[value];
                }
                written += 1;
            }
        }
        return @intCast(output_length);
    }
    if (mode != 1) return -1;
    const encoded_length = length - 1;
    var content_length = encoded_length;
    for (0..encoded_length) |i| {
        if (input[i + 1] == '=') { content_length = i; break; }
    }
    const padding = encoded_length - content_length;
    for (0..content_length) |i| if (base32Value(input[i + 1]) < 0) return -1;
    for (content_length..encoded_length) |i| if (input[i + 1] != '=') return -1;
    const remainder = content_length % 8;
    const expected_padding: usize = switch (remainder) { 0 => 0, 2 => 6, 4 => 4, 5 => 3, 7 => 1, else => return -1 };
    if (padding != 0 and (encoded_length % 8 != 0 or padding != expected_padding)) return -1;
    if (content_length != 0 and remainder != 0) {
        const final_value: usize = @intCast(base32Value(input[content_length]));
        const unused: usize = switch (remainder) { 2 => 2, 4 => 4, 5 => 1, else => 3 };
        if ((final_value & ((@as(usize, 1) << @intCast(unused)) - 1)) != 0) return -1;
    }
    const output_length = content_length * 5 / 8;
    if (output_capacity < output_length) return -2;
    for (0..output_length) |i| {
        var byte: u8 = 0;
        for (i * 8..i * 8 + 8) |bit| {
            const symbol: usize = @intCast(base32Value(input[1 + bit / 5]));
            byte = (byte << 1) | @as(u8, @intCast((symbol >> @intCast(4 - bit % 5)) & 1));
        }
        output[i] = byte;
    }
    return @intCast(output_length);
}
