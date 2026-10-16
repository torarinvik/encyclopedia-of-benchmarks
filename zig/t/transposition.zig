const MAX_KEY: usize = 32;
const MAX_TEXT: usize = 512;
const MAX_INPUT: usize = 3 + MAX_KEY + MAX_TEXT;
const MAX_PADDED: usize = MAX_TEXT + MAX_KEY;

fn hashByte(hash: *u64, byte: u8) void {
    hash.* = (hash.* ^ byte) *% 1099511628211;
}

fn outputHash(text: *const [MAX_PADDED]u8, length: usize) i64 {
    var hash: u64 = 14695981039346656037;
    const count: u64 = @intCast(length);
    for (0..8) |index| hashByte(&hash, @truncate(count >> @intCast(index * 8)));
    for (0..length) |index| {
        const codepoint: u32 = text[index];
        for (0..4) |byte_index| hashByte(&hash, @truncate(codepoint >> @intCast(byte_index * 8)));
    }
    return @intCast(hash & 0x7fffffffffffffff);
}

export fn transposition(input_pointer: ?[*]const i64, length: usize) i64 {
    if (length < 4 or length > MAX_INPUT) return -1;
    const input = input_pointer orelse return -1;
    const mode = input[0];
    const key_length_value = input[1];
    if ((mode != 0 and mode != 1) or key_length_value < 1 or key_length_value > 32) return -1;
    const key_length: usize = @intCast(key_length_value);
    const text_length_index = 2 + key_length;
    if (length <= text_length_index) return -1;
    const text_length_value = input[text_length_index];
    if (text_length_value < 1 or text_length_value > 512) return -1;
    const text_length: usize = @intCast(text_length_value);
    if (length != text_length_index + 1 + text_length) return -1;

    var key = [_]u8{0} ** MAX_KEY;
    var sorted = [_]u8{0} ** MAX_KEY;
    for (0..key_length) |index| {
        const value = input[2 + index];
        if (!((value >= 65 and value <= 90) or (value >= 97 and value <= 122))) return -1;
        var ch: u8 = @intCast(value);
        if (ch >= 65 and ch <= 90) ch += 32;
        key[index] = ch;
        sorted[index] = ch;
    }
    for (1..key_length) |index| {
        const value = sorted[index];
        var cursor = index;
        while (cursor > 0 and sorted[cursor - 1] > value) {
            sorted[cursor] = sorted[cursor - 1];
            cursor -= 1;
        }
        sorted[cursor] = value;
    }
    var ranks = [_]usize{0} ** MAX_KEY;
    for (0..key_length) |index| {
        var first: usize = 0;
        while (first < key_length and sorted[first] != key[index]) : (first += 1) {}
        var duplicate: usize = 0;
        for (0..index) |prior| {
            if (key[prior] == key[index]) duplicate += 1;
        }
        ranks[index] = first + duplicate + 1;
    }

    var text = [_]u8{0} ** MAX_PADDED;
    for (0..text_length) |index| {
        const value = input[text_length_index + 1 + index];
        if (value < 32 or value > 126) return -1;
        text[index] = @intCast(value);
    }
    if (mode == 0 and text[text_length - 1] == 32) return -1;
    const padded_length = text_length + key_length - text_length % key_length;
    for (text_length..padded_length) |index| text[index] = 32;

    var result = [_]u8{0} ** MAX_PADDED;
    var result_length: usize = 0;
    if (mode == 0) {
        var start: usize = 0;
        while (start < padded_length) : (start += key_length) {
            var block = [_]u8{0} ** MAX_KEY;
            for (0..key_length) |offset| block[ranks[offset] - 1] = text[start + offset];
            for (0..key_length) |offset| {
                result[result_length] = block[offset];
                result_length += 1;
            }
        }
    } else {
        var start: usize = 0;
        while (start < text_length) : (start += key_length) {
            for (0..key_length) |offset| {
                result[result_length] = text[start + ranks[offset] - 1];
                result_length += 1;
            }
        }
        while (result_length > 0 and result[result_length - 1] == 32) result_length -= 1;
    }
    return outputHash(&result, result_length);
}
