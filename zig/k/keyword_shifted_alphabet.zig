const MAX_KEYWORD_LENGTH: usize = 26;
const MAX_MESSAGE_LENGTH: usize = 512;
const MAX_INPUT_LENGTH: usize = 3 + MAX_KEYWORD_LENGTH + MAX_MESSAGE_LENGTH + 1;

export fn keyword_shifted_alphabet(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const operation = input[0];
    const keyword_length_value = input[1];
    const message_length_value = input[2];
    if ((operation != 0 and operation != 1) or keyword_length_value < 1 or keyword_length_value > 26 or
        message_length_value < 1 or message_length_value > MAX_MESSAGE_LENGTH) return -1;
    const keyword_length: usize = @intCast(keyword_length_value);
    const message_length: usize = @intCast(message_length_value);
    if (length != 3 + keyword_length + message_length) return -1;

    var keyword: [MAX_KEYWORD_LENGTH]u8 = @splat(0);
    var seen: [26]bool = @splat(false);
    for (0..keyword_length) |i| {
        const value = input[3 + i];
        if (!((value >= 65 and value <= 90) or (value >= 97 and value <= 122))) return -1;
        const lower: u8 = @intCast(if (value >= 65 and value <= 90) value + 32 else value);
        const index: usize = @intCast(lower - 'a');
        if (seen[index]) return -1;
        seen[index] = true;
        keyword[i] = lower;
    }
    var message: [MAX_MESSAGE_LENGTH]u8 = @splat(0);
    for (0..message_length) |i| {
        const value = input[3 + keyword_length + i];
        if (value < 0 or value > 127) return -1;
        message[i] = @intCast(value);
    }

    var cipher_alphabet: [26]u8 = @splat(0);
    var encode: [26]u8 = @splat(0);
    var decode: [26]u8 = @splat(0);
    var cipher_length: usize = 0;
    for (0..keyword_length) |i| {
        cipher_alphabet[cipher_length] = keyword[i];
        cipher_length += 1;
    }
    for (0..26) |i| {
        const letter: u8 = @intCast('a' + i);
        if (!seen[i]) {
            cipher_alphabet[cipher_length] = letter;
            cipher_length += 1;
        }
    }
    for (0..26) |i| {
        encode[i] = cipher_alphabet[i];
        decode[@intCast(cipher_alphabet[i] - 'a')] = @intCast('a' + i);
    }

    if (output_capacity < message_length or output == null) return -2;
    for (0..message_length) |i| {
        const value = message[i];
        const uppercase = value >= 'A' and value <= 'Z';
        var index: ?usize = null;
        if (uppercase) {
            index = @intCast(value - 'A');
        } else if (value >= 'a' and value <= 'z') {
            index = @intCast(value - 'a');
        }
        if (index) |letter_index| {
            const translated = if (operation == 0) encode[letter_index] else decode[letter_index];
            output[i] = if (uppercase) translated - 32 else translated;
        } else {
            output[i] = value;
        }
    }
    return @intCast(message_length);
}
