/* Emit the Rust z_array convention: z[0] is zero and later entries are prefix lengths. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 2047

int64_t z_algorithm(const int64_t *input, size_t length,
                    uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_LENGTH + 1) return -1;
    if (input[0] < 0 || input[0] > MAX_LENGTH) return -1;
    const size_t count = (size_t)input[0];
    if (length != count + 1) return -1;
    const size_t output_bytes = count * 4;
    if (output_capacity < output_bytes || (count != 0 && output == NULL)) return -2;

    size_t z[MAX_LENGTH] = {0};
    size_t left = 0, right = 0;
    for (size_t index = 1; index < count; ++index) {
        if (index < right) {
            const size_t reused = z[index - left];
            const size_t remaining = right - index;
            z[index] = reused < remaining ? reused : remaining;
        }
        while (index + z[index] < count && input[1 + z[index]] == input[1 + index + z[index]])
            ++z[index];
        if (index + z[index] > right) {
            left = index;
            right = index + z[index];
        }
    }
    for (size_t index = 0; index < count; ++index) {
        const uint32_t value = (uint32_t)z[index];
        for (size_t byte = 0; byte < 4; ++byte)
            output[index * 4 + byte] = (uint8_t)(value >> (byte * 8));
    }
    return (int64_t)count;
}
