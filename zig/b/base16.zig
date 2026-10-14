/// Encode bytes as uppercase Base16 or decode uppercase Base16 bytes.
export fn base16(input: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > 65) return -1;
    const mode = input[0];
    if (mode == 0) {
        const count = length - 1;
        const output_length = count * 2;
        for (1..length) |index| if (input[index] < 0 or input[index] > 255) return -1;
        if (output_capacity < output_length) return -2;
        for (0..count) |index| {
            const byte: u8 = @intCast(input[index + 1]);
            output[2 * index] = "0123456789ABCDEF"[byte >> 4];
            output[2 * index + 1] = "0123456789ABCDEF"[byte & 15];
        }
        return @intCast(output_length);
    }
    if (mode != 1) return -1;
    const encoded_length = length - 1;
    if (encoded_length % 2 != 0) return -1;
    for (1..length) |index| if (nibble(input[index]) < 0) return -1;
    const output_length = encoded_length / 2;
    if (output_capacity < output_length) return -2;
    for (0..output_length) |index| {
        output[index] = @intCast(nibble(input[1 + 2 * index]) * 16 + nibble(input[2 + 2 * index]));
    }
    return @intCast(output_length);
}
fn nibble(byte: i64) i64 {
    if (byte >= '0' and byte <= '9') return byte - '0';
    if (byte >= 'A' and byte <= 'F') return byte - 'A' + 10;
    return -1;
}
