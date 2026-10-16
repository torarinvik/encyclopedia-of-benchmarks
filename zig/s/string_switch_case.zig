const max_text_length: usize = 1024;
const max_input_length: usize = max_text_length + 3;

fn isSpace(value: i64) bool {
    return value == 32 or (value >= 9 and value <= 13) or (value >= 28 and value <= 31);
}

fn isWord(value: i64) bool {
    return (value >= 65 and value <= 90) or (value >= 97 and value <= 122) or
        (value >= 48 and value <= 57);
}

export fn string_switch_case(input: [*c]const i64, length: usize,
                             output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > max_input_length) return -1;
    const mode = input[0];
    const separator = input[1];
    const text_length = input[2];
    if (mode < 0 or mode > 8 or separator < 0 or separator > 127 or
        text_length < 0 or text_length > max_text_length or
        length != @as(usize, @intCast(text_length)) + 3 or
        ((mode != 3 and mode != 4) and separator != 0)) return -1;
    const count: usize = @intCast(text_length);
    for (0..count) |i| {
        if (input[i + 3] < 0 or input[i + 3] > 127) return -1;
    }

    var result: [max_text_length]u8 = @splat(0);
    var used: usize = 0;
    if (mode <= 2) {
        var at_word_start = true;
        for (0..count) |i| {
            var value = input[i + 3];
            if (!isWord(value)) {
                at_word_start = true;
                continue;
            }
            if (at_word_start) {
                if (value >= 97 and value <= 122) value -= 32;
                at_word_start = false;
            } else if (value >= 65 and value <= 90) {
                value += 32;
            }
            result[used] = @intCast(value);
            used += 1;
        }
        if (mode == 2) {
            if (used == 0) {
                const message = "not valid string";
                @memcpy(result[0..message.len], message);
                used = message.len;
            } else if (result[0] >= 'A' and result[0] <= 'Z') {
                result[0] += 32;
            }
        }
    } else {
        const upper = mode == 4 or mode == 6 or mode == 8;
        const delimiter: u8 = if (mode <= 4) @intCast(separator) else if (mode <= 6) '_' else '-';
        var group_has_word = false;
        var pending_space = false;
        for (0..count) |i| {
            var value = input[i + 3];
            if (isSpace(value)) {
                if (group_has_word) pending_space = true;
                continue;
            }
            if (!isWord(value)) {
                group_has_word = false;
                pending_space = false;
                continue;
            }
            if (pending_space and group_has_word) {
                result[used] = delimiter;
                used += 1;
            }
            pending_space = false;
            if (upper and value >= 97 and value <= 122) value -= 32
            else if (!upper and value >= 65 and value <= 90) value += 32;
            result[used] = @intCast(value);
            used += 1;
            group_has_word = true;
        }
    }
    if (used > capacity or (used > 0 and output == null)) return -2;
    for (0..used) |i| output[i] = result[i];
    return @intCast(used);
}
