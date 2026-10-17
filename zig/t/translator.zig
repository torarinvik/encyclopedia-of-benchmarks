const MAX_KEYS: usize = 4;
const MAX_KEY_LENGTH: usize = 4;
const MAX_TEXT_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 107;
const MAX_OUTPUT_LENGTH: usize = 256;

export fn translator(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 or input[0] > 4 or input[1] < 0 or input[1] > 64) return -1;
    const key_count: usize = @intCast(input[0]);
    const text_length: usize = @intCast(input[1]);
    var keys: [MAX_KEYS][MAX_KEY_LENGTH]u8 = undefined;
    var replacements: [MAX_KEYS][MAX_KEY_LENGTH]u8 = undefined;
    var key_lengths = [_]usize{0} ** MAX_KEYS;
    var replacement_lengths = [_]usize{0} ** MAX_KEYS;
    var cursor: usize = 2;
    for (0..key_count) |key_index| {
        if (cursor + 2 > length) return -1;
        const key_length_value = input[cursor];
        const value_length_value = input[cursor + 1];
        cursor += 2;
        if (key_length_value < 1 or key_length_value > 4 or value_length_value < 0 or value_length_value > 4) return -1;
        const key_length: usize = @intCast(key_length_value);
        const value_length: usize = @intCast(value_length_value);
        if (cursor + key_length + value_length > length) return -1;
        for (0..key_length) |index| {
            const byte = input[cursor + index];
            if (byte < 32 or byte > 126) return -1;
            keys[key_index][index] = @intCast(byte);
        }
        cursor += key_length;
        for (0..value_length) |index| {
            const byte = input[cursor + index];
            if (byte < 32 or byte > 126) return -1;
            replacements[key_index][index] = @intCast(byte);
        }
        cursor += value_length;
        key_lengths[key_index] = key_length;
        replacement_lengths[key_index] = value_length;
        for (0..key_index) |previous| {
            if (key_lengths[previous] == key_length) {
                var equal = true;
                for (0..key_length) |index| if (keys[previous][index] != keys[key_index][index]) { equal = false; break; };
                if (equal) return -1;
            }
        }
    }
    if (cursor + text_length != length) return -1;
    var text: [MAX_TEXT_LENGTH]u8 = undefined;
    for (0..text_length) |index| {
        const byte = input[cursor + index];
        if (byte < 32 or byte > 126) return -1;
        text[index] = @intCast(byte);
    }

    var result: [MAX_OUTPUT_LENGTH]u8 = undefined;
    var result_length: usize = 0;
    var start: usize = 0;
    while (start < text_length) {
        var matched = false;
        const remaining = text_length - start;
        const maximum_length = if (remaining < MAX_KEY_LENGTH) remaining else MAX_KEY_LENGTH;
        var candidate_length: usize = 1;
        while (candidate_length <= maximum_length and !matched) : (candidate_length += 1) {
            for (0..key_count) |key_index| {
                if (key_lengths[key_index] != candidate_length) continue;
                var equal = true;
                for (0..candidate_length) |index| if (text[start + index] != keys[key_index][index]) { equal = false; break; };
                if (!equal) continue;
                for (0..replacement_lengths[key_index]) |index| result[result_length + index] = replacements[key_index][index];
                result_length += replacement_lengths[key_index];
                start += candidate_length;
                matched = true;
                break;
            }
        }
        if (!matched) break;
    }
    if (output == null or capacity < result_length) return -2;
    if (result_length > 0) @memcpy(output[0..result_length], result[0..result_length]);
    return @intCast(result_length);
}
