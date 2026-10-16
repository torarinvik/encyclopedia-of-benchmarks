module hamming_distance_strings;

const usz MAX_STRING_LENGTH = 128;
const usz MAX_INPUT_LENGTH = 260;

fn long hamming_distance_strings(long* input, usz length) @export("hamming_distance_strings") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long left_length = input[0], right_length = input[1];
    if (left_length < 0 || left_length > (long)MAX_STRING_LENGTH || right_length < 0 || right_length > (long)MAX_STRING_LENGTH) return -1;
    if (length != 2 + (usz)left_length + (usz)right_length) return -1;
    for (usz i = 2; i < length; i++) if (input[i] < 0 || input[i] > 255) return -1;
    if (left_length != right_length) return -1;
    long distance = 0;
    for (long i = 0; i < left_length; i++) if (input[2 + (usz)i] != input[2 + (usz)left_length + (usz)i]) distance++;
    return distance;
}
