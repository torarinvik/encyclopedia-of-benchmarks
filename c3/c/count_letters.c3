module count_letters;

const usz MAX_TEXT_LENGTH = 256;

fn long lowercase_ascii_letter(long value) {
    return value >= 'A' && value <= 'Z' ? value + ('a' - 'A') : value;
}

fn long count_letters(long* input, usz length) @export("count_letters") {
    if (input == null || length < 2 || input[1] < 0 || input[1] > (long)MAX_TEXT_LENGTH) return -1;
    usz text_length = (usz)input[1];
    if (length != text_length + 2) return -1;
    long query = lowercase_ascii_letter(input[0]);
    if (query < 'a' || query > 'z') return -1;
    long count = 0;
    for (usz index = 0; index < text_length; index++) {
        long value = input[index + 2];
        if (!((value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z'))) return -1;
        if (lowercase_ascii_letter(value) == query) count++;
    }
    return count;
}
