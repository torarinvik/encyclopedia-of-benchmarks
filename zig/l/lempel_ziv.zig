const MAX_BIT_COUNT: usize = 128;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 130;
const MAX_OUTPUT_BYTES: usize = 1032;
const MAX_DICTIONARY_ENTRIES: usize = 130;
const MAX_KEY_LENGTH: usize = 129;
const MAX_CODE_WIDTH: usize = 8;

export fn lempel_ziv(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 1 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const bit_count_value = input[0];
    if (bit_count_value < 0 or bit_count_value > MAX_BIT_COUNT) return -1;
    const bit_count: usize = @intCast(bit_count_value);
    if (input_length != 1 + bit_count) return -1;
    for (0..bit_count) |index| {
        if (input[index + 1] != 48 and input[index + 1] != 49) return -1;
    }

    var keys = [_]u8{0} ** (MAX_DICTIONARY_ENTRIES * MAX_KEY_LENGTH);
    var key_lengths = [_]usize{0} ** MAX_DICTIONARY_ENTRIES;
    var codes = [_]u8{0} ** (MAX_DICTIONARY_ENTRIES * MAX_CODE_WIDTH);
    var code_lengths = [_]usize{0} ** MAX_DICTIONARY_ENTRIES;
    keys[0] = 48;
    keys[MAX_KEY_LENGTH] = 49;
    key_lengths[0] = 1;
    key_lengths[1] = 1;
    codes[0] = 48;
    codes[MAX_CODE_WIDTH] = 49;
    code_lengths[0] = 1;
    code_lengths[1] = 1;
    var entry_count: usize = 2;
    var next_index: usize = 2;
    var current = [_]u8{0} ** MAX_KEY_LENGTH;
    var current_length: usize = 0;
    var result = [_]u8{0} ** MAX_OUTPUT_BYTES;
    var result_length: usize = 0;

    for (0..bit_count) |input_index| {
        current[current_length] = @intCast(input[input_index + 1]);
        current_length += 1;
        var found: usize = entry_count;
        for (0..entry_count) |entry| {
            if (key_lengths[entry] == current_length) {
                var matched = true;
                for (0..current_length) |component| {
                    if (keys[entry * MAX_KEY_LENGTH + component] != current[component]) {
                        matched = false;
                        break;
                    }
                }
                if (matched) {
                    found = entry;
                    break;
                }
            }
        }
        if (found == entry_count) continue;

        const last_code_length = code_lengths[found];
        var last_code = [_]u8{0} ** MAX_CODE_WIDTH;
        for (0..last_code_length) |component| {
            last_code[component] = codes[found * MAX_CODE_WIDTH + component];
            result[result_length] = last_code[component];
            result_length += 1;
        }
        for (found..entry_count - 1) |entry| {
            for (0..MAX_KEY_LENGTH) |component| {
                keys[entry * MAX_KEY_LENGTH + component] = keys[(entry + 1) * MAX_KEY_LENGTH + component];
            }
            for (0..MAX_CODE_WIDTH) |component| {
                codes[entry * MAX_CODE_WIDTH + component] = codes[(entry + 1) * MAX_CODE_WIDTH + component];
            }
            key_lengths[entry] = key_lengths[entry + 1];
            code_lengths[entry] = code_lengths[entry + 1];
        }
        entry_count -= 1;
        for (0..current_length) |component| {
            keys[entry_count * MAX_KEY_LENGTH + component] = current[component];
        }
        keys[entry_count * MAX_KEY_LENGTH + current_length] = 48;
        key_lengths[entry_count] = current_length + 1;
        for (0..last_code_length) |component| {
            codes[entry_count * MAX_CODE_WIDTH + component] = last_code[component];
        }
        code_lengths[entry_count] = last_code_length;
        entry_count += 1;

        if ((next_index & (next_index - 1)) == 0) {
            for (0..entry_count) |entry| {
                const code_length = code_lengths[entry];
                var component = code_length;
                while (component > 0) {
                    codes[entry * MAX_CODE_WIDTH + component] = codes[entry * MAX_CODE_WIDTH + component - 1];
                    component -= 1;
                }
                codes[entry * MAX_CODE_WIDTH] = 48;
                code_lengths[entry] = code_length + 1;
            }
        }
        for (0..current_length) |component| {
            keys[entry_count * MAX_KEY_LENGTH + component] = current[component];
        }
        keys[entry_count * MAX_KEY_LENGTH + current_length] = 49;
        key_lengths[entry_count] = current_length + 1;
        var code_width: usize = 1;
        var temp = next_index;
        while (temp > 1) {
            temp >>= 1;
            code_width += 1;
        }
        code_lengths[entry_count] = code_width;
        for (0..code_width) |component| {
            const bit = (next_index >> (code_width - component - 1)) & 1;
            codes[entry_count * MAX_CODE_WIDTH + component] = 48 + @as(u8, @intCast(bit));
        }
        entry_count += 1;
        next_index += 1;
        current_length = 0;
    }

    if (current_length > 0) {
        var max_key_length: usize = 0;
        for (0..entry_count) |entry| {
            if (key_lengths[entry] > max_key_length) max_key_length = key_lengths[entry];
        }
        var found: usize = entry_count;
        while (found == entry_count) {
            for (0..entry_count) |entry| {
                if (key_lengths[entry] == current_length) {
                    var matched = true;
                    for (0..current_length) |component| {
                        if (keys[entry * MAX_KEY_LENGTH + component] != current[component]) {
                            matched = false;
                            break;
                        }
                    }
                    if (matched) {
                        found = entry;
                        break;
                    }
                }
            }
            if (found == entry_count) {
                if (current_length >= max_key_length) break;
                current[current_length] = 48;
                current_length += 1;
            }
        }
        if (found == entry_count) return -1;
        for (0..code_lengths[found]) |component| {
            result[result_length] = codes[found * MAX_CODE_WIDTH + component];
            result_length += 1;
        }
    }
    if (output == null or output_capacity < result_length) return -2;
    for (0..result_length) |index| output[index] = result[index];
    return @intCast(result_length);
}
