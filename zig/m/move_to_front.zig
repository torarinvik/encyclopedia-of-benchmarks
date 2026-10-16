const MAX_ALPHABET_LENGTH: usize = 32;
const MAX_TEXT_LENGTH: usize = 128;

export fn move_to_front(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 3 or length > 164) return -1;
    const mode = values[0];
    const alphabet_length = values[1];
    const text_length = values[2];
    if ((mode != 0 and mode != 1) or alphabet_length < 0 or alphabet_length > MAX_ALPHABET_LENGTH
        or text_length < 0 or text_length > MAX_TEXT_LENGTH
        or length != 3 + @as(usize, @intCast(alphabet_length + text_length))) return -1;
    var alphabet = [_]i64{0} ** MAX_ALPHABET_LENGTH;
    var result = [_]u8{0} ** MAX_TEXT_LENGTH;
    for (0..@as(usize, @intCast(alphabet_length))) |i| {
        const symbol = values[3 + i];
        if (symbol < 0 or symbol > 127) return -1;
        for (0..i) |j| if (alphabet[j] == symbol) return -1;
        alphabet[i] = symbol;
    }
    var result_length: usize = 0;
    if (mode == 0) {
        if (text_length > 0 and alphabet_length == 0) return -1;
        for (0..@as(usize, @intCast(text_length))) |i| {
            const symbol = values[3 + @as(usize, @intCast(alphabet_length)) + i];
            if (symbol < 0 or symbol > 127) return -1;
            var position: usize = 0;
            while (position < @as(usize, @intCast(alphabet_length)) and alphabet[position] != symbol) : (position += 1) {}
            if (position == @as(usize, @intCast(alphabet_length))) return -1;
            result[result_length] = @intCast(position);
            result_length += 1;
            var j = position;
            while (j > 0) : (j -= 1) alphabet[j] = alphabet[j - 1];
            alphabet[0] = symbol;
        }
    } else if (alphabet_length > 0) {
        for (0..@as(usize, @intCast(text_length))) |i| {
            const index = values[3 + @as(usize, @intCast(alphabet_length)) + i];
            if (index < 0 or index >= alphabet_length) return -1;
            const position: usize = @intCast(index);
            const symbol = alphabet[position];
            result[result_length] = @intCast(symbol);
            result_length += 1;
            var j = position;
            while (j > 0) : (j -= 1) alphabet[j] = alphabet[j - 1];
            alphabet[0] = symbol;
        }
    }
    if (capacity < result_length or (result_length > 0 and output == null)) return -2;
    for (0..result_length) |i| output[i] = result[i];
    return @intCast(result_length);
}
