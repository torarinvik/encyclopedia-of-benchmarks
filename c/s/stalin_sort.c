/* Keep each value that is not smaller than the last retained value. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 128

int64_t stalin_sort(const int64_t *values, size_t length,
                    uint8_t *output, size_t output_capacity)
{
    if (length > MAX_INPUT_LENGTH || (length != 0 && values == NULL)) return -1;
    for (size_t i = 0; i < length; ++i)
        if (values[i] < INT32_MIN || values[i] > INT32_MAX) return -1;

    size_t kept = 0;
    int64_t last = 0;
    for (size_t i = 0; i < length; ++i) {
        if (kept == 0 || values[i] >= last) {
            ++kept;
            last = values[i];
        }
    }
    const size_t output_bytes = kept * 4;
    if (output == NULL || output_capacity < output_bytes) return -2;

    size_t output_index = 0;
    last = 0;
    for (size_t i = 0; i < length; ++i) {
        if (output_index == 0 || values[i] >= last) {
            const uint32_t bits = (uint32_t)(int32_t)values[i];
            for (size_t byte = 0; byte < 4; ++byte)
                output[output_index * 4 + byte] = (uint8_t)(bits >> (byte * 8));
            ++output_index;
            last = values[i];
        }
    }
    return (int64_t)output_bytes;
}
