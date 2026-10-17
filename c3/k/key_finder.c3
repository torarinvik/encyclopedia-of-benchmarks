module key_finder;

const long MAX_TEXT_LENGTH = 256;
const usz MAX_INPUT_LENGTH = 258;
const char*[24] WORD_BANK = {
    "I ", "You ", "We ", "They ", "He ", "She ", "It ", " the ",
    "The ", " of ", " is ", "Is ", " am ", "Am ", " are ", "Are ",
    " have ", "Have ", " has ", "Has ", " may ", "May ", " be ", "Be "
};
const usz[24] WORD_LENGTHS = {2,4,3,5,3,4,3,5,4,4,4,3,4,3,5,4,6,5,5,4,5,4,4,3};

fn long shift_ascii_letter(long code, long key) {
    if (code >= 65 && code <= 90) return 65 + (code - 65 + key) % 26;
    if (code >= 97 && code <= 122) return 97 + (code - 97 + key) % 26;
    return code;
}

fn long key_finder(long* input, usz length) @export("key_finder") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long text_length_value = input[0];
    if (text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH) return -1;
    usz text_length = (usz)text_length_value;
    if (length != text_length + 1) return -1;
    for (usz index = 0; index < text_length; index++) {
        long code = input[index + 1];
        if (code < 32 || code > 126 || (code >= 48 && code <= 57)) return -1;
    }

    for (long key = 0; key < 26; key++) {
        for (usz start = 0; start < text_length; start++) {
            for (usz word = 0; word < 24; word++) {
                usz word_length = WORD_LENGTHS[word];
                if (start + word_length > text_length) continue;
                usz offset = 0;
                while (offset < word_length) {
                    if (shift_ascii_letter(input[start + offset + 1], key)
                            != (long)WORD_BANK[word][offset]) break;
                    offset++;
                }
                if (offset == word_length) return key;
            }
        }
    }
    return 0;
}
