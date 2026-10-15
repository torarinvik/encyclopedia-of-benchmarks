module permutation_in_string;

const usz MAX_STRING_LENGTH = 1024;
const usz MAX_INPUT_LENGTH = 2050;

fn void adjust_count(long* differences, long* nonzero, usz letter, long amount) {
    if (differences[letter] == 0) { (*nonzero)++; }
    differences[letter] += amount;
    if (differences[letter] == 0) { (*nonzero)--; }
}

// Check for a permutation of one lowercase ASCII string inside another.
fn long permutation_in_string(long* input, usz length) @export("permutation_in_string") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) { return -1; }
    long first_length_value = input[0];
    long second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > 1024 || second_length_value < 0 || second_length_value > 1024) { return -1; }
    usz first_length = (usz)first_length_value;
    usz second_length = (usz)second_length_value;
    if (length != 2 + first_length + second_length) { return -1; }
    for (usz index = 2; index < length; index++) {
        if (input[index] < 97 || input[index] > 122) { return -1; }
    }
    if (first_length > second_length) { return 0; }

    long[26] differences;
    long nonzero = 0;
    for (usz index = 0; index < first_length; index++) {
        adjust_count(&differences[0], &nonzero, (usz)(input[2 + index] - 97), 1);
        adjust_count(&differences[0], &nonzero, (usz)(input[2 + first_length + index] - 97), -1);
    }
    if (nonzero == 0) { return 1; }
    for (usz start = 0; start < second_length - first_length; start++) {
        usz outgoing = 2 + first_length + start;
        usz incoming = outgoing + first_length;
        adjust_count(&differences[0], &nonzero, (usz)(input[outgoing] - 97), 1);
        adjust_count(&differences[0], &nonzero, (usz)(input[incoming] - 97), -1);
        if (nonzero == 0) { return 1; }
    }
    return 0;
}
