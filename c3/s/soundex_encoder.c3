module soundex_encoder;

const usz MAX_TEXT_LENGTH = 64;
const usz MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 1;
const usz MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 2;
const usz MAX_OUTPUT_BYTES = 4;

fn bool is_ascii_letter(long value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

fn long digit_for(long value) {
    if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
    if (value == 'a' || value == 'e' || value == 'i' || value == 'o' || value == 'u' || value == 'y') return 0;
    if (value == 'h' || value == 'w') return 8;
    if (value == 'b' || value == 'f' || value == 'p' || value == 'v') return 1;
    if (value == 'c' || value == 'g' || value == 'j' || value == 'k' || value == 'q' || value == 's' ||
        value == 'x' || value == 'z') return 2;
    if (value == 'd' || value == 't') return 3;
    if (value == 'l') return 4;
    if (value == 'm' || value == 'n') return 5;
    if (value == 'r') return 6;
    return -1;
}

fn long soundex_encoder(long* values, usz length, char* output, usz output_capacity)
        @export("soundex_encoder") {
    if (length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH || values == null) return -1;
    long text_length = values[0];
    if (text_length < 1 || text_length > MAX_TEXT_LENGTH || length > MAX_INPUT_LENGTH ||
        length != text_length.usz() + 1) return -1;
    for (usz index = 1; index < length; index++)
        if (!is_ascii_letter(values[index])) return -1;

    long[MAX_TEXT_LENGTH] mapped;
    usz mapped_count = 0;
    for (usz index = 1; index < length; index++) {
        long letter = values[index];
        if (letter >= 'A' && letter <= 'Z') letter += 'a' - 'A';
        if (letter == 'h' || letter == 'w') continue;
        long digit = digit_for(letter);
        if (mapped_count == 0 || mapped[mapped_count - 1] != digit) {
            mapped[mapped_count] = digit;
            mapped_count++;
        }
    }

    usz code_count = 0;
    for (usz index = 0; index < mapped_count; index++)
        if (mapped[index] != 0) {
            mapped[code_count] = mapped[index];
            code_count++;
        }
    if (code_count == 0) return -1;

    long first_letter = values[1];
    if (first_letter >= 'A' && first_letter <= 'Z') first_letter += 'a' - 'A';
    usz start = 0;
    if (mapped[0] == digit_for(first_letter)) {
        if (code_count == 1) return -1;
        start = 1;
    }

    char[4] encoded;
    long initial = values[1];
    if (initial >= 'a' && initial <= 'z') initial -= 'a' - 'A';
    encoded[0] = (char)initial;
    for (usz index = 0; index < 3; index++) {
        long digit = start + index < code_count ? mapped[start + index] : 0;
        encoded[index + 1] = (char)('0' + digit);
    }

    if (output == null || output_capacity < MAX_OUTPUT_BYTES) return -2;
    for (usz index = 0; index < MAX_OUTPUT_BYTES; index++) output[index] = encoded[index];
    return (long)MAX_OUTPUT_BYTES;
}
