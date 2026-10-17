module playfair_cipher;

const usz MAX_KEY_LENGTH = 25;
const usz MAX_TEXT_LENGTH = 128;
const usz MAX_PARSEABLE_INPUT_VALUES = 157;
const ulong FNV_OFFSET_BASIS = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;
const ulong LOW_63_MASK = 0x7fffffffffffffff;
const char[26] ALPHABET = "ABCDEFGHIKLMNOPQRSTUVWXYZ";

fn bool is_letter(long value) {
    return value >= 'A' && value <= 'Z' && value != 'J';
}

fn void add_square_letter(int* square, bool* seen, usz* count, int letter) {
    if (seen[letter]) return;
    seen[letter] = true;
    square[*count] = letter;
    *count = *count + 1;
}

fn ulong hash_byte(ulong hash, int byte) {
    return (hash ^ (ulong)(uint)byte) * FNV_PRIME;
}

fn long playfair_cipher(long* input, usz input_length) @export("playfair_cipher") {
    if (input == null || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    long operation = input[0];
    long raw_key_length = input[1];
    if ((operation != 0 && operation != 1) || raw_key_length < 0 || raw_key_length > (long)MAX_KEY_LENGTH) return -1;

    usz key_length = (usz)raw_key_length;
    usz text_length_index = 2 + key_length;
    if (input_length <= text_length_index) return -1;
    long raw_text_length = input[text_length_index];
    if (raw_text_length < 0 || raw_text_length > (long)MAX_TEXT_LENGTH || (raw_text_length & 1) != 0) return -1;
    usz text_length = (usz)raw_text_length;
    if (input_length != text_length_index + 1 + text_length) return -1;

    int[MAX_KEY_LENGTH] key = zeroed;
    int[MAX_TEXT_LENGTH] text = zeroed;
    for (usz index = 0; index < key_length; index++) {
        long value = input[2 + index];
        if (!is_letter(value)) return -1;
        key[index] = (int)value;
    }
    for (usz index = 0; index < text_length; index++) {
        long value = input[text_length_index + 1 + index];
        if (!is_letter(value)) return -1;
        text[index] = (int)value;
    }
    if (operation == 0) {
        for (usz index = 0; index + 1 < text_length; index++) {
            if (text[index] == text[index + 1]) return -1;
        }
    }

    int[25] square = zeroed;
    bool[128] seen = zeroed;
    usz square_length = 0;
    for (usz index = 0; index < key_length; index++) {
        add_square_letter(&square[0], &seen[0], &square_length, key[index]);
    }
    for (usz index = 0; index < 25; index++) {
        add_square_letter(&square[0], &seen[0], &square_length, (int)ALPHABET[index]);
    }

    int[128] position = zeroed;
    for (usz index = 0; index < 128; index++) position[index] = -1;
    for (usz index = 0; index < square_length; index++) position[(usz)square[index]] = (int)index;

    ulong hash = FNV_OFFSET_BASIS;
    int direction = operation == 0 ? 1 : -1;
    for (usz index = 0; index < text_length; index += 2) {
        int first = position[(usz)text[index]];
        int second = position[(usz)text[index + 1]];
        int row1 = first / 5;
        int column1 = first % 5;
        int row2 = second / 5;
        int column2 = second % 5;
        int output_first;
        int output_second;

        if (row1 == row2) {
            int next_column1 = (column1 + direction + 5) % 5;
            int next_column2 = (column2 + direction + 5) % 5;
            output_first = square[row1 * 5 + next_column1];
            output_second = square[row2 * 5 + next_column2];
        } else if (column1 == column2) {
            int next_row1 = (row1 + direction + 5) % 5;
            int next_row2 = (row2 + direction + 5) % 5;
            output_first = square[next_row1 * 5 + column1];
            output_second = square[next_row2 * 5 + column2];
        } else {
            output_first = square[row1 * 5 + column2];
            output_second = square[row2 * 5 + column1];
        }
        hash = hash_byte(hash, output_first);
        hash = hash_byte(hash, output_second);
    }

    return (long)(hash & LOW_63_MASK);
}
