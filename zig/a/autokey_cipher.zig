/// Plaintext-autokey cipher with a selectable output case dialect.
const max_autokey_length = 1024;

fn uppercaseLetter(value: i64) i64 {
    return if (value >= 'a' and value <= 'z') value - 32 else value;
}

export fn autokey_cipher(input: [*]const i64, length: usize,
                         output: [*]u8, output_capacity: usize) i64 {
    if (length < 6 or length > 2052) return -1;
    const mode = input[0];
    const dialect = input[1];
    const text_length_value = input[2];
    const key_length_value = input[3];
    if ((mode != 0 and mode != 1) or (dialect != 0 and dialect != 1)
        or text_length_value < 1 or text_length_value > max_autokey_length
        or key_length_value < 1 or key_length_value > max_autokey_length) return -1;
    const text_length: usize = @intCast(text_length_value);
    const key_length: usize = @intCast(key_length_value);
    if (length != 4 + text_length + key_length) return -1;
    const key_start = 4 + text_length;
    for (0..text_length) |index| {
        const value = input[4 + index];
        if (!((value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z'))) return -1;
        if (dialect == 1 and mode == 1 and value >= 'A' and value <= 'Z') return -1;
    }
    for (0..key_length) |index| {
        const value = input[key_start + index];
        if (!((value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z'))) return -1;
    }
    if (output_capacity < text_length) return -2;
    for (0..text_length) |index| {
        const plain = uppercaseLetter(input[4 + index]) - 'A';
        const key_value = if (index < key_length) uppercaseLetter(input[key_start + index])
            else if (mode == 0) uppercaseLetter(input[4 + index - key_length])
            else uppercaseLetter(@as(i64, output[index - key_length]));
        const shift = key_value - 'A';
        const mapped = if (mode == 0) @mod(plain + shift, 26) else @mod(plain - shift + 26, 26);
        const result = 'A' + mapped + (if (dialect == 1) 32 else 0);
        output[index] = @intCast(result);
    }
    return @intCast(text_length);
}
