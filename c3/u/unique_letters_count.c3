module unique_letters_count;

const usz MAX_TEXT_LENGTH = 256;
const usz MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 1;
const usz LETTER_COUNT = 26;
const usz BYTES_PER_RECORD = 8;
const usz BYTES_PER_I32 = 4;

fn void store_i32_le(char* output, usz position, long value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < BYTES_PER_I32; byte += 1) {
        output[position + byte] = (char)((bits >> (byte * 8)) & 255);
    }
}

fn long unique_letters_count(long* input, usz length, char* output, usz output_capacity)
    @export("unique_letters_count") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_TEXT_LENGTH ||
        length != 1 + (usz)input[0]) return -1;

    usz text_length = (usz)input[0];
    for (usz index = 0; index < text_length; index += 1) {
        if (input[index + 1] < 0 || input[index + 1] > 127) return -1;
    }

    long[LETTER_COUNT] frequencies;
    int[LETTER_COUNT] first_seen;
    for (usz letter = 0; letter < LETTER_COUNT; letter += 1) frequencies[letter] = 0;
    usz unique_count = 0;
    for (usz index = 0; index < text_length; index += 1) {
        long byte = input[index + 1];
        if (byte >= 'A' && byte <= 'Z') {
            byte += 'a' - 'A';
        } else if (byte < 'a' || byte > 'z') {
            continue;
        }
        usz letter_index = (usz)(byte - 'a');
        if (frequencies[letter_index] == 0) {
            first_seen[unique_count] = (int)byte;
            unique_count += 1;
        }
        frequencies[letter_index] += 1;
    }

    usz maximum_result = text_length < LETTER_COUNT ? text_length : LETTER_COUNT;
    usz required_capacity = maximum_result * BYTES_PER_RECORD;
    if (output_capacity < required_capacity || (required_capacity > 0 && output == null)) return -2;

    for (usz index = 0; index < unique_count; index += 1) {
        int letter = first_seen[index];
        store_i32_le(output, index * BYTES_PER_RECORD, (long)letter);
        store_i32_le(output, index * BYTES_PER_RECORD + BYTES_PER_I32,
                     frequencies[(usz)(letter - 'a')]);
    }
    return (long)unique_count;
}
