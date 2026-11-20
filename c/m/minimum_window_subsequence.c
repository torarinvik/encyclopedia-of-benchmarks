#include <stddef.h>
#include <stdint.h>

#define MAX_SEARCH_LENGTH 128
#define MAX_PATTERN_LENGTH 128
#define MAX_INPUT_LENGTH 258

int64_t minimum_window_subsequence(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_SEARCH_LENGTH) return -1;
    size_t search_length = (size_t)input[0];
    size_t pattern_length_index = search_length + 1;
    if (length <= pattern_length_index) return -1;
    int64_t pattern_length_value = input[pattern_length_index];
    if (pattern_length_value < 1 || pattern_length_value > MAX_PATTERN_LENGTH) return -1;
    size_t pattern_length = (size_t)pattern_length_value;
    if (length != search_length + pattern_length + 2) return -1;

    for (size_t i = 0; i < search_length; ++i)
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    for (size_t j = 0; j < pattern_length; ++j)
        if (input[search_length + 2 + j] < 0 || input[search_length + 2 + j] > 127) return -1;

    int8_t latest_start[MAX_PATTERN_LENGTH];
    for (size_t j = 0; j < pattern_length; ++j) latest_start[j] = -1;
    int best_start = -1;
    size_t best_length = search_length + 1;
    for (size_t end = 0; end < search_length; ++end) {
        int64_t byte = input[end + 1];
        for (size_t j = pattern_length; j > 0; --j) {
            size_t pattern_index = j - 1;
            if (byte != input[search_length + 2 + pattern_index]) continue;
            int candidate = pattern_index == 0 ? (int)end : (int)latest_start[pattern_index - 1];
            if (candidate >= 0 && candidate > latest_start[pattern_index])
                latest_start[pattern_index] = (int8_t)candidate;
        }
        if (byte == input[search_length + 2 + pattern_length - 1] && latest_start[pattern_length - 1] >= 0) {
            int start = (int)latest_start[pattern_length - 1];
            size_t window_length = end - (size_t)start + 1;
            if (window_length < best_length ||
                (window_length == best_length && (best_start < 0 || start < best_start))) {
                best_start = start;
                best_length = window_length;
            }
        }
    }
    if (best_start < 0) return 0;
    if (best_length > capacity || output == NULL) return -2;
    for (size_t i = 0; i < best_length; ++i)
        output[i] = (uint8_t)input[(size_t)best_start + 1 + i];
    return (int64_t)best_length;
}
