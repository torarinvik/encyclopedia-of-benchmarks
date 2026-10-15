module is_subsequence;

const usz MAX_SEQUENCE_LENGTH = 4096;
const usz MAX_PACKED_LENGTH = 8194;

fn bool is_unicode_scalar(long value) {
    return value >= 0 && value <= 1114111 && !(value >= 55296 && value <= 57343);
}

fn long is_subsequence(long* input, usz length) @export("is_subsequence") {
    if (input == null || length < 2 || length > MAX_PACKED_LENGTH ||
        input[0] < 0 || input[0] > (long)MAX_SEQUENCE_LENGTH ||
        input[1] < 0 || input[1] > (long)MAX_SEQUENCE_LENGTH) return -1;
    usz main_length = (usz)input[0];
    usz subsequence_length = (usz)input[1];
    if (length != 2 + main_length + subsequence_length) return -1;
    for (usz index = 2; index < length; index++)
        if (!is_unicode_scalar(input[index])) return -1;

    usz subsequence_start = 2 + main_length;
    usz main_index = 0, subsequence_index = 0;
    while (subsequence_index < subsequence_length && main_index < main_length) {
        if (input[subsequence_start + subsequence_index] == input[2 + main_index]) subsequence_index++;
        main_index++;
    }
    return subsequence_index == subsequence_length ? 1 : 0;
}
