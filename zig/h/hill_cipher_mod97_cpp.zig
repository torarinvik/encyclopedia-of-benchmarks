const alphabet = [_]u8{65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 126, 33, 64, 35, 36, 37, 94, 38, 42, 40, 41, 95, 43, 96, 45, 61, 91, 93, 123, 125, 124, 59, 39, 34, 58, 44, 46, 47, 60, 62, 63, 92, 13, 10, 32};
const encrypt_key = [_]i64{2, 5, 1, 6};
const decrypt_key = [_]i64{84, 27, 83, 28};

fn alphabetIndex(value: i64) ?usize {
    for (alphabet, 0..) |character, index| if (@as(i64, character) == value) return index;
    return null;
}

export fn hill_cipher_mod97_cpp(values: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length < 3 or length > 258) return -1;
    const input = values.?[0..length];
    const operation = input[0];
    const raw_length = input[1];
    if ((operation != 0 and operation != 1) or raw_length < 1 or raw_length > 256 or length != @as(usize, @intCast(raw_length)) + 2) return -1;
    const text_length: usize = @intCast(raw_length);
    var indices: [256]u8 = @splat(0);
    for (0..text_length) |index| {
        const mapped = alphabetIndex(input[index + 2]) orelse return -1;
        indices[index] = @intCast(mapped);
    }
    const output_length = text_length + text_length % 2;
    if (output == null or output_capacity < output_length) return -2;
    const key = if (operation == 0) encrypt_key else decrypt_key;
    const result = output.?[0..output_capacity];
    for (0..output_length / 2) |block| {
        const offset = block * 2;
        const first: i64 = indices[offset];
        const second: i64 = if (offset + 1 < text_length) indices[offset + 1] else 0;
        const row0: usize = @intCast(@mod(key[0] * first + key[1] * second, 97));
        const row1: usize = @intCast(@mod(key[2] * first + key[3] * second, 97));
        result[offset] = alphabet[row0];
        result[offset + 1] = alphabet[row1];
    }
    return @intCast(output_length);
}
