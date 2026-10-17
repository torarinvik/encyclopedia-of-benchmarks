#include <stddef.h>
#include <stdint.h>

enum { SJT_MAX_LENGTH = 6 };

static void sjt_emit_row(const int32_t *values, size_t length, uint8_t *output, size_t *offset)
{
    for (size_t index = 0; index < length; ++index) {
        uint32_t bits = (uint32_t)values[index];
        for (size_t byte = 0; byte < 4; ++byte)
            output[(*offset)++] = (uint8_t)(bits >> (8U * (unsigned int)byte));
    }
}

int64_t steinhaus_johnson_trotter(const int32_t *input, size_t length,
                                  uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length == 0 || length > SJT_MAX_LENGTH) return -1;
    size_t permutations = 1;
    for (size_t factor = 2; factor <= length; ++factor) permutations *= factor;
    size_t required = 4 * length * permutations;
    if (output == NULL || output_capacity < required) return -2;

    int32_t values[SJT_MAX_LENGTH];
    size_t inversion[SJT_MAX_LENGTH] = {0};
    for (size_t index = 0; index < length; ++index) values[index] = input[index];
    size_t offset = 0;
    sjt_emit_row(values, length, output, &offset);

    size_t index = 1;
    while (index < length) {
        if (inversion[index] < index) {
            size_t swap_index = index % 2 == 0 ? 0 : inversion[index];
            int32_t temporary = values[swap_index];
            values[swap_index] = values[index];
            values[index] = temporary;
            sjt_emit_row(values, length, output, &offset);
            inversion[index] += 1;
            index = 1;
        } else {
            inversion[index] = 0;
            index += 1;
        }
    }
    return (int64_t)required;
}
