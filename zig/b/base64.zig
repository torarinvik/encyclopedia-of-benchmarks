/// Encode and decode bytes with the RFC 4648 Base64 alphabet.
fn base64Value(byte: i64) i64 {
    if (byte >= 'A' and byte <= 'Z') return byte - 'A';
    if (byte >= 'a' and byte <= 'z') return byte - 'a' + 26;
    if (byte >= '0' and byte <= '9') return byte - '0' + 52;
    if (byte == '+') return 62;
    if (byte == '/') return 63;
    return -1;
}

export fn base64(input: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > 66) return -1;
    const mode = input[0];
    if (mode == 0) {
        const count = length - 1;
        for (1..length) |i| if (input[i] < 0 or input[i] > 255) return -1;
        const output_length = if (count == 0) 0 else ((count + 2) / 3) * 4;
        const symbols: usize = (count * 8 + 5) / 6;
        if (output_capacity < output_length) return -2;
        for (0..output_length) |i| {
            if (i >= symbols) {
                output[i] = '=';
            } else {
                var value: u8 = 0;
                for (i * 6..i * 6 + 6) |bit| {
                    value <<= 1;
                    if (bit < count * 8) {
                        const byte: u8 = @intCast(input[1 + bit / 8]);
                        value |= (byte >> @intCast(7 - bit % 8)) & 1;
                    }
                }
                output[i] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"[value];
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
    for (0..content_length) |i| if (base64Value(input[i + 1]) < 0) return -1;
    for (content_length..encoded_length) |i| if (input[i + 1] != '=') return -1;
    const remainder = content_length % 4;
    const expected_padding: usize = switch (remainder) { 0 => 0, 2 => 2, 3 => 1, else => return -1 };
    if (padding != 0 and (encoded_length % 4 != 0 or padding != expected_padding)) return -1;
    if (content_length != 0 and remainder != 0) {
        const final_value: usize = @intCast(base64Value(input[content_length]));
        const unused: usize = if (remainder == 2) 4 else 2;
        if ((final_value & ((@as(usize, 1) << @intCast(unused)) - 1)) != 0) return -1;
    }
    const output_length = content_length * 6 / 8;
    if (output_capacity < output_length) return -2;
    for (0..output_length) |i| {
        var byte: u8 = 0;
        for (i * 8..i * 8 + 8) |bit| {
            const symbol: usize = @intCast(base64Value(input[1 + bit / 6]));
            byte = (byte << 1) | @as(u8, @intCast((symbol >> @intCast(5 - bit % 6)) & 1));
        }
        output[i] = byte;
    }
    return @intCast(output_length);
}
