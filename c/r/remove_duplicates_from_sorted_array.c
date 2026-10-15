/* Compact each value in an ascending array to its first occurrence. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t remove_duplicates_from_sorted_array(const int64_t *input, size_t length,
                                            uint8_t *output, size_t output_capacity)
{
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return -1;
    size_t unique_count = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = input[index];
        if (value < INT32_MIN || value > INT32_MAX ||
            (index != 0 && input[index - 1] > value)) return -1;
        if (index == 0 || input[index - 1] != value) ++unique_count;
    }
    const size_t output_bytes = unique_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;
    size_t written = 0;
    for (size_t index = 0; index < length; ++index) {
        if (index == 0 || input[index - 1] != input[index]) {
            const uint32_t bits = (uint32_t)(int32_t)input[index];
            for (size_t byte = 0; byte < 4; ++byte)
                output[written * 4 + byte] = (uint8_t)(bits >> (byte * 8));
            ++written;
        }
    }
    return written == unique_count ? (int64_t)written : -1;
}
