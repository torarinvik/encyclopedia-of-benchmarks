const MAX_BIT_COUNT: usize = 128;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 130;
const MAX_OUTPUT_BYTES: usize = 8256;
const MAX_DICTIONARY_ENTRIES: usize = 130;
const MAX_PHRASE_LENGTH: usize = 129;

export fn lempel_ziv_decompress(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 1 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const bit_count_value = input[0];
    if (bit_count_value < 0 or bit_count_value > MAX_BIT_COUNT) return -1;
    const bit_count: usize = @intCast(bit_count_value);
    if (input_length != 1 + bit_count) return -1;
    for (0..bit_count) |index| {
        if (input[index + 1] != 48 and input[index + 1] != 49) return -1;
    }

    var codes = [_]usize{0} ** MAX_DICTIONARY_ENTRIES;
    var phrase_lengths = [_]usize{0} ** MAX_DICTIONARY_ENTRIES;
    var phrases = [_]u8{0} ** (MAX_DICTIONARY_ENTRIES * MAX_PHRASE_LENGTH);
    codes[0] = 0;
    codes[1] = 1;
    phrase_lengths[0] = 1;
    phrase_lengths[1] = 1;
    phrases[0] = 48;
    phrases[MAX_PHRASE_LENGTH] = 49;
    var entry_count: usize = 2;
    var code_width: usize = 1;
    var next_index: usize = 2;
    var result = [_]u8{0} ** MAX_OUTPUT_BYTES;
    var result_length: usize = 0;
    var cursor: usize = 0;

    while (cursor + code_width <= bit_count) {
        const code_width_used = code_width;
        var code: usize = 0;
        for (0..code_width_used) |bit_offset| {
            code = code * 2 + @as(usize, @intCast(input[cursor + bit_offset + 1] - 48));
        }
        var found: usize = entry_count;
        for (0..entry_count) |index| {
            if (codes[index] == code) {
                found = index;
                break;
            }
        }
        if (found == entry_count) break;

        const last_length = phrase_lengths[found];
        var last_phrase = [_]u8{0} ** MAX_PHRASE_LENGTH;
        for (0..last_length) |index| {
            const value = phrases[found * MAX_PHRASE_LENGTH + index];
            last_phrase[index] = value;
            result[result_length] = value;
            result_length += 1;
        }
        phrases[found * MAX_PHRASE_LENGTH + last_length] = 48;
        phrase_lengths[found] = last_length + 1;

        if ((next_index & (next_index - 1)) == 0) {
            code_width += 1;
        }
        codes[entry_count] = next_index;
        phrase_lengths[entry_count] = last_length + 1;
        for (0..last_length) |index| {
            phrases[entry_count * MAX_PHRASE_LENGTH + index] = last_phrase[index];
        }
        phrases[entry_count * MAX_PHRASE_LENGTH + last_length] = 49;
        entry_count += 1;
        next_index += 1;
        cursor += code_width_used;
    }
    if (output == null or output_capacity < result_length) return -2;
    for (0..result_length) |index| output[index] = result[index];
    return @intCast(result_length);
}
