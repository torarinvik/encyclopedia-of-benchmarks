module find_the_difference;

const MAX_STRING_LENGTH = 4096;
const MAX_PACKED_LENGTH = 8195;

// Return the lowercase byte added to t by subtracting the two character sums.
fn long find_the_difference(long* input, usz length) @export("find_the_difference") {
    if (input == null || length < 2 || length > MAX_PACKED_LENGTH) { return -1; }
    if (input[0] < 0 || input[0] > MAX_STRING_LENGTH ||
        input[1] < 1 || input[1] > MAX_STRING_LENGTH + 1) { return -1; }
    usz s_length = (usz)input[0];
    usz t_length = (usz)input[1];
    if (t_length != s_length + 1 || length != 2 + s_length + t_length) { return -1; }
    long sum_s = 0;
    long sum_t = 0;
    for (usz index = 0; index < s_length; index++) {
        long value = input[2 + index];
        if (value < 97 || value > 122) { return -1; }
        sum_s += value;
    }
    usz t_start = 2 + s_length;
    for (usz index = 0; index < t_length; index++) {
        long value = input[t_start + index];
        if (value < 97 || value > 122) { return -1; }
        sum_t += value;
    }
    long difference = sum_t - sum_s;
    if (difference < 97 || difference > 122) { return -1; }
    return difference;
}
