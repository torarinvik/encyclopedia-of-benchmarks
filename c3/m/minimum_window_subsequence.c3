module minimum_window_subsequence;

const usz MAX_INPUT_LENGTH = 258;
const usz MAX_SEARCH_LENGTH = 128;
const usz MAX_PATTERN_LENGTH = 128;

fn long minimum_window_subsequence(long* input, usz length, char* output, usz capacity)
    @export("minimum_window_subsequence") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_SEARCH_LENGTH) return -1;
    usz search_length = (usz)input[0];
    usz pattern_length_index = search_length + 1;
    if (length <= pattern_length_index) return -1;
    long pattern_length_value = input[pattern_length_index];
    if (pattern_length_value < 1 || pattern_length_value > (long)MAX_PATTERN_LENGTH) return -1;
    usz pattern_length = (usz)pattern_length_value;
    if (length != search_length + pattern_length + 2) return -1;

    for (usz i = 0; i < search_length; i++)
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    for (usz j = 0; j < pattern_length; j++)
        if (input[search_length + 2 + j] < 0 || input[search_length + 2 + j] > 127) return -1;

    int8[MAX_PATTERN_LENGTH] latest_start = {};
    for (usz j = 0; j < pattern_length; j++) latest_start[j] = -1;
    long best_start = -1;
    usz best_length = search_length + 1;
    for (usz end = 0; end < search_length; end++) {
        long byte = input[end + 1];
        for (usz j = pattern_length; j > 0; j--) {
            usz pattern_index = j - 1;
            if (byte != input[search_length + 2 + pattern_index]) continue;
            long candidate = pattern_index == 0 ? (long)end : (long)latest_start[pattern_index - 1];
            if (candidate >= 0 && candidate > (long)latest_start[pattern_index])
                latest_start[pattern_index] = (int8)candidate;
        }
        if (byte == input[search_length + 2 + pattern_length - 1] && latest_start[pattern_length - 1] >= 0) {
            long start = (long)latest_start[pattern_length - 1];
            usz window_length = end - (usz)start + 1;
            if (window_length < best_length ||
                (window_length == best_length && (best_start < 0 || start < best_start))) {
                best_start = start;
                best_length = window_length;
            }
        }
    }
    if (best_start < 0) return 0;
    if (best_length > capacity || output == null) return -2;
    for (usz i = 0; i < best_length; i++)
        output[i] = (char)input[(usz)best_start + 1 + i];
    return (long)best_length;
}
