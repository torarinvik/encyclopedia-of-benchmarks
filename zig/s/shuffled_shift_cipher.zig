const MAX_PASSCODE_LENGTH: usize = 20;
const MAX_TEXT_LENGTH: usize = 256;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 279;
const ALPHABET_LENGTH: usize = 97;

fn isAsciiAlphanumeric(value: i64) bool {
    return (value >= 48 and value <= 57) or (value >= 65 and value <= 90) or (value >= 97 and value <= 122);
}

export fn shuffled_shift_cipher(input: [*c]const i64, input_length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const pass_length_value = input[0];
    const text_length_value = input[1];
    if (pass_length_value < 1 or pass_length_value > MAX_PASSCODE_LENGTH or text_length_value < 0 or text_length_value > MAX_TEXT_LENGTH) return -1;
    const pass_length: usize = @intCast(pass_length_value);
    const text_length: usize = @intCast(text_length_value);
    if (input_length != 2 + pass_length + text_length) return -1;

    var passcode = [_]u8{0} ** MAX_PASSCODE_LENGTH;
    for (0..pass_length) |index| {
        const value = input[index + 2];
        if (!isAsciiAlphanumeric(value)) return -1;
        passcode[index] = @intCast(value);
    }
    const text_start = 2 + pass_length;
    var plaintext = [_]u8{0} ** MAX_TEXT_LENGTH;
    for (0..text_length) |index| {
        const value = input[text_start + index];
        if (!((value >= 32 and value <= 126) or value == 9 or value == 10)) return -1;
        plaintext[index] = @intCast(value);
    }
    if (output == null or output_capacity < text_length) return -2;

    var breakpoints = [_]bool{false} ** 128;
    var shift_sum: i64 = 0;
    for (0..pass_length) |index| {
        const byte = passcode[index];
        breakpoints[@as(usize, byte)] = true;
        if (index % 2 == 0) {
            shift_sum += @as(i64, byte);
        } else {
            shift_sum -= @as(i64, byte);
        }
    }
    const shift: usize = if (shift_sum > 0) @intCast(shift_sum) else pass_length;

    var alphabet = [_]u8{0} ** ALPHABET_LENGTH;
    var alphabet_length: usize = 0;
    for (97..123) |value| {
        alphabet[alphabet_length] = @intCast(value);
        alphabet_length += 1;
    }
    for (65..91) |value| {
        alphabet[alphabet_length] = @intCast(value);
        alphabet_length += 1;
    }
    for (48..58) |value| {
        alphabet[alphabet_length] = @intCast(value);
        alphabet_length += 1;
    }
    for (33..127) |value| {
        if (!isAsciiAlphanumeric(@intCast(value))) {
            alphabet[alphabet_length] = @intCast(value);
            alphabet_length += 1;
        }
    }
    alphabet[alphabet_length] = 32;
    alphabet_length += 1;
    alphabet[alphabet_length] = 9;
    alphabet_length += 1;
    alphabet[alphabet_length] = 10;
    alphabet_length += 1;

    var key = [_]u8{0} ** ALPHABET_LENGTH;
    var segment = [_]u8{0} ** ALPHABET_LENGTH;
    var key_length: usize = 0;
    var segment_length: usize = 0;
    for (0..alphabet_length) |index| {
        const byte = alphabet[index];
        segment[segment_length] = byte;
        segment_length += 1;
        if (breakpoints[@as(usize, byte)] or index + 1 == alphabet_length) {
            while (segment_length > 0) {
                segment_length -= 1;
                key[key_length] = segment[segment_length];
                key_length += 1;
            }
        }
    }

    for (0..text_length) |index| {
        var key_index: usize = 0;
        while (key_index < key_length and key[key_index] != plaintext[index]) : (key_index += 1) {}
        output[index] = key[(key_index + shift) % ALPHABET_LENGTH];
    }
    return @intCast(text_length);
}
