/* Remove every occurrence of target while preserving the surviving order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t remove_element(const int64_t *input, size_t length,
                      uint8_t *output, size_t output_capacity)
{
    if (length == 0 || length > MAX_LENGTH || input == NULL) return -1;
    const int64_t target = input[0];
    if (target < INT32_MIN || target > INT32_MAX) return -1;
    size_t survivor_count = 0;
    for (size_t index = 1; index < length; ++index) {
        const int64_t value = input[index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (value != target) ++survivor_count;
    }
    const size_t output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;
    size_t written = 0;
    for (size_t index = 1; index < length; ++index) {
        if (input[index] != target) {
            const uint32_t bits = (uint32_t)(int32_t)input[index];
            for (size_t byte = 0; byte < 4; ++byte)
                output[written * 4 + byte] = (uint8_t)(bits >> (byte * 8));
            ++written;
        }
    }
    return written == survivor_count ? (int64_t)written : -1;
}
