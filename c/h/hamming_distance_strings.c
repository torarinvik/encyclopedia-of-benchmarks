#include <stddef.h>
#include <stdint.h>

#define MAX_STRING_LENGTH INT64_C(128)
#define MAX_INPUT_LENGTH (2 + 2 * (MAX_STRING_LENGTH + 1))

int64_t hamming_distance_strings(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t left_length = input[0];
    const int64_t right_length = input[1];
    if (left_length < 0 || left_length > MAX_STRING_LENGTH || right_length < 0 || right_length > MAX_STRING_LENGTH) return -1;
    if (length != (size_t)(2 + left_length + right_length)) return -1;
    for (size_t i = 2; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    if (left_length != right_length) return -1;
    int64_t distance = 0;
    for (int64_t i = 0; i < left_length; ++i) {
        if (input[2 + (size_t)i] != input[2 + (size_t)left_length + (size_t)i]) ++distance;
    }
    return distance;
}
