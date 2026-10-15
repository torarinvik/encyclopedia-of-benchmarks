/* Replace thymine with uracil in an uppercase ASCII sequence. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_VALUES 1001

int64_t dna2_rna(const int64_t *values, size_t length,
                 uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_VALUES || values[0] != 0) return -1;
    const size_t count = length - 1;
    for (size_t index = 1; index < length; ++index)
        if (values[index] < 'A' || values[index] > 'Z') return -1;
    if (output_capacity < count || (count != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < count; ++index) {
        const int64_t base = values[index + 1];
        output[index] = (uint8_t)(base == 'T' ? 'U' : base);
    }
    return (int64_t)count;
}
