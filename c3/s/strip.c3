module strip;

const usz MAX_TEXT_LENGTH = 256;
const usz MAX_CHARACTER_LENGTH = 128;

fn bool strip_contains(long value, long* input, usz set_start, long set_length) {
    if (set_length == -1) return value == 9 || value == 10 || value == 13 || value == 32;
    for (usz i = 0; i < (usz)set_length; i++)
        if (input[set_start + i] == value) return true;
    return false;
}

fn long strip(long* input, usz length, uint8* output, usz output_capacity) @export("strip") {
    if (input == null || length < 2 || length > 386) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_TEXT_LENGTH) return -1;
    usz text_length = (usz)input[0];
    usz set_index = 1 + text_length;
    if (set_index >= length) return -1;
    long set_length = input[set_index];
    usz expected_length;
    if (set_length == -1) expected_length = set_index + 1;
    else {
        if (set_length < 0 || set_length > (long)MAX_CHARACTER_LENGTH) return -1;
        expected_length = set_index + 1 + (usz)set_length;
    }
    if (length != expected_length) return -1;
    for (usz i = 0; i < text_length; i++)
        if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    if (set_length >= 0)
        for (usz i = 0; i < (usz)set_length; i++)
            if (input[set_index + 1 + i] < 0 || input[set_index + 1 + i] > 127) return -1;

    usz start = 0;
    usz end = text_length;
    while (start < end && strip_contains(input[1 + start], input, set_index + 1, set_length)) start++;
    while (end > start && strip_contains(input[end], input, set_index + 1, set_length)) end--;
    usz output_length = end - start;
    if (output_capacity < output_length || (output_length > 0 && output == null)) return -2;
    for (usz i = 0; i < output_length; i++) output[i] = (uint8)input[1 + start + i];
    return (long)output_length;
}
