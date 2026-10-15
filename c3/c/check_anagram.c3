module check_anagram;

const usz MAX_STRING_LENGTH = 1024;
const usz MAX_INPUT_LENGTH = 2050;

fn int letter_index(long value) {
    if (value >= 97 && value <= 122) return (int)(value - 97);
    if (value >= 65 && value <= 90) return (int)(value - 65);
    return -1;
}

// Case-insensitive anagram check for distinct ASCII alphabetic strings.
fn long check_anagram(long* input, usz length) @export("check_anagram") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long first_length_value = input[0], second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > 1024 || second_length_value < 0 || second_length_value > 1024) return -1;
    usz first_length = (usz)first_length_value;
    usz second_length = (usz)second_length_value;
    if (length != 2 + first_length + second_length) return -1;

    usz[26] first_counts;
    usz[26] second_counts;
    for (usz index = 0; index < first_length; index++) {
        int letter = letter_index(input[2 + index]);
        if (letter < 0) return -1;
        first_counts[(usz)letter]++;
    }
    for (usz index = 0; index < second_length; index++) {
        int letter = letter_index(input[2 + first_length + index]);
        if (letter < 0) return -1;
        second_counts[(usz)letter]++;
    }
    if (first_length != second_length) return 0;
    bool different_after_normalization = false;
    for (usz index = 0; index < first_length; index++) {
        if (letter_index(input[2 + index]) != letter_index(input[2 + first_length + index]))
            different_after_normalization = true;
    }
    if (!different_after_normalization) return 0;
    for (usz letter = 0; letter < 26; letter++)
        if (first_counts[letter] != second_counts[letter]) return 0;
    return 1;
}
