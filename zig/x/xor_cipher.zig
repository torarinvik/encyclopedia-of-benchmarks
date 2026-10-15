/// XOR each input byte with a repeating key byte sequence.
export fn xor_cipher(input: [*c]const i64, length: usize,
                     output: [*c]u8, output_capacity: usize) i64 {
    if (length < 3 or length > 66 or input[0] < 0 or input[0] > 63 or
        input[1] < 1 or input[1] > 63) return -1;
    const text_length: usize = @intCast(input[0]);
    const key_length: usize = @intCast(input[1]);
    if (length != 2 + text_length + key_length) return -1;
    for (0..text_length + key_length) |index| {
        const value = input[2 + index];
        if (value < 0 or value > 255) return -1;
    }
    if (output_capacity < text_length) return -2;
    for (0..text_length) |index| {
        output[index] = @intCast(input[2 + index] ^ input[2 + text_length + index % key_length]);
    }
    return @intCast(text_length);
}
