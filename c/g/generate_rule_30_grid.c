#include <stddef.h>
#include <stdint.h>

#define MAX_WIDTH 64
#define MAX_GENERATIONS 64

int64_t generate_rule_30_grid(const int64_t *input, size_t length,
                              uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length != 2) return -1;
    const int64_t width_value = input[0];
    const int64_t generations_value = input[1];
    if (width_value < 1 || width_value > MAX_WIDTH ||
        generations_value < 1 || generations_value > MAX_GENERATIONS) return -1;
    const size_t width = (size_t)width_value;
    const size_t generations = (size_t)generations_value;
    const size_t output_count = width * generations;
    if (output_capacity < output_count || output == NULL) return -2;

    int64_t current[MAX_WIDTH] = {0};
    int64_t next[MAX_WIDTH] = {0};
    current[width / 2] = 1;
    for (size_t column = 0; column < width; ++column) output[column] = (uint8_t)current[column];
    for (size_t generation = 1; generation < generations; ++generation) {
        for (size_t column = 0; column < width; ++column) {
            const int64_t left = column > 0 ? current[column - 1] : 0;
            const int64_t right = column + 1 < width ? current[column + 1] : 0;
            const unsigned pattern = (unsigned)(left * 4 + current[column] * 2 + right);
            next[column] = (30u >> pattern) & 1u;
        }
        for (size_t column = 0; column < width; ++column) {
            current[column] = next[column];
            output[generation * width + column] = (uint8_t)next[column];
        }
    }
    return (int64_t)output_count;
}
