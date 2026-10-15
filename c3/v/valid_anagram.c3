module valid_anagram;

const usz MAX_STRING_LENGTH = 1024;
const usz MAX_INPUT_LENGTH = 2050;

// Compare lowercase ASCII strings by their letter frequencies.
fn long valid_anagram(long* input, usz length) @export("valid_anagram") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) { return -1; }
    long first_length_value = input[0];
    long second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > 1024 || second_length_value < 0 || second_length_value > 1024) { return -1; }
    usz first_length = (usz)first_length_value;
    usz second_length = (usz)second_length_value;
    if (length != 2 + first_length + second_length) { return -1; }
    usz[26] first_counts;
    usz[26] second_counts;
    for (usz index = 0; index < first_length; index++) {
        long value = input[2 + index];
        if (value < 97 || value > 122) { return -1; }
        first_counts[(usz)(value - 97)]++;
    }
    for (usz index = 0; index < second_length; index++) {
        long value = input[2 + first_length + index];
        if (value < 97 || value > 122) { return -1; }
        second_counts[(usz)(value - 97)]++;
    }
    for (usz letter = 0; letter < 26; letter++) {
        if (first_counts[letter] != second_counts[letter]) { return 0; }
    }
    return 1;
}
