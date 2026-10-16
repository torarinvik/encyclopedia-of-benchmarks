module common_characters_frequency_quotient;

const usz MAX_INPUT_LENGTH = 1 + 16 * (1 + 64);

fn long common_characters_frequency_quotient(long* input, usz length,
        char* output, usz capacity) @export("common_characters_frequency_quotient") {
    if (input == null || length == 0 || length > MAX_INPUT_LENGTH) return -1;
    long string_count = input[0];
    if (string_count < 0 || string_count > 16) return -1;
    long[26] counts = {0};
    usz offset = 1, total = 0;
    for (long string_index = 0; string_index < string_count; string_index++) {
        if (offset >= length) return -1;
        long string_length = input[offset++];
        if (string_length < 0 || string_length > 64 || (usz)string_length > length - offset) return -1;
        for (long i = 0; i < string_length; i++) {
            long value = input[offset++];
            if (value < 97 || value > 122) return -1;
            counts[value - 97]++;
        }
        total += (usz)string_length;
        if (total > 512) return -1;
    }
    if (offset != length) return -1;
    usz used = 0;
    if (string_count > 0) {
        for (usz letter = 0; letter < 26; letter++) used += (usz)(counts[letter] / string_count);
    }
    if (used > capacity || (used > 0 && output == null)) return -2;
    usz output_offset = 0;
    if (string_count > 0) {
        for (usz letter = 0; letter < 26; letter++) {
            for (long copy = 0; copy < counts[letter] / string_count; copy++) {
                output[output_offset++] = (char)(97 + letter);
            }
        }
    }
    return (long)used;
}
