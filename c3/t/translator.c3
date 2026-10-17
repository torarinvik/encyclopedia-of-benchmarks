module translator;

const usz MAX_KEYS = 4;
const usz MAX_KEY_LENGTH = 4;
const usz MAX_TEXT_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 107;
const usz MAX_OUTPUT_LENGTH = 256;

fn long translator(long* input, usz length, uint8* output, usz capacity) @export("translator") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > 4 || input[1] < 0 || input[1] > 64) return -1;
    usz key_count = (usz)input[0], text_length = (usz)input[1];
    uint8 keys[4][4] = {{0}}, replacements[4][4] = {{0}};
    usz key_lengths[4] = {0}, replacement_lengths[4] = {0};
    usz cursor = 2;
    for (usz key_index = 0; key_index < key_count; key_index++) {
        if (cursor + 2 > length) return -1;
        long key_length_value = input[cursor++], value_length_value = input[cursor++];
        if (key_length_value < 1 || key_length_value > 4 || value_length_value < 0 || value_length_value > 4) return -1;
        usz key_length = (usz)key_length_value, value_length = (usz)value_length_value;
        if (cursor + key_length + value_length > length) return -1;
        for (usz index = 0; index < key_length; index++) {
            long byte = input[cursor + index];
            if (byte < 32 || byte > 126) return -1;
            keys[key_index][index] = (uint8)byte;
        }
        cursor += key_length;
        for (usz index = 0; index < value_length; index++) {
            long byte = input[cursor + index];
            if (byte < 32 || byte > 126) return -1;
            replacements[key_index][index] = (uint8)byte;
        }
        cursor += value_length;
        key_lengths[key_index] = key_length;
        replacement_lengths[key_index] = value_length;
        for (usz previous = 0; previous < key_index; previous++) {
            if (key_lengths[previous] != key_length) continue;
            bool equal = true;
            for (usz index = 0; index < key_length; index++) if (keys[previous][index] != keys[key_index][index]) equal = false;
            if (equal) return -1;
        }
    }
    if (cursor + text_length != length) return -1;
    uint8 text[64];
    for (usz index = 0; index < text_length; index++) {
        long byte = input[cursor + index];
        if (byte < 32 || byte > 126) return -1;
        text[index] = (uint8)byte;
    }

    uint8 result[256];
    usz result_length = 0, start = 0;
    while (start < text_length) {
        bool matched = false;
        usz remaining = text_length - start;
        usz maximum_length = remaining < MAX_KEY_LENGTH ? remaining : MAX_KEY_LENGTH;
        for (usz candidate_length = 1; candidate_length <= maximum_length && !matched; candidate_length++) {
            for (usz key_index = 0; key_index < key_count; key_index++) {
                if (key_lengths[key_index] != candidate_length) continue;
                bool equal = true;
                for (usz index = 0; index < candidate_length; index++) if (text[start + index] != keys[key_index][index]) equal = false;
                if (!equal) continue;
                for (usz index = 0; index < replacement_lengths[key_index]; index++) result[result_length + index] = replacements[key_index][index];
                result_length += replacement_lengths[key_index];
                start += candidate_length;
                matched = true;
                break;
            }
        }
        if (!matched) break;
    }
    if (output == null || capacity < result_length) return -2;
    for (usz index = 0; index < result_length; index++) output[index] = result[index];
    return (long)result_length;
}
