/* Emit unique ASCII permutations in sorted depth-first order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 6

static void generate(const int32_t *values, size_t n, size_t depth,
                     int32_t *current, uint8_t *used, uint8_t *output,
                     size_t *result_count)
{
    if (depth == n) {
        const size_t row_start = *result_count * n;
        for (size_t index = 0; index < n; ++index)
            output[row_start + index] = (uint8_t)current[index];
        ++*result_count;
        return;
    }
    for (size_t index = 0; index < n; ++index) {
        if (used[index]) continue;
        if (index > 0 && values[index] == values[index - 1] && !used[index - 1]) continue;
        current[depth] = values[index];
        used[index] = 1;
        generate(values, n, depth + 1, current, used, output, result_count);
        used[index] = 0;
    }
}

int64_t unique_permutation(const int64_t *input, size_t length,
                           uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_LENGTH + 1) return -1;
    if (input[0] < 0 || input[0] > MAX_LENGTH || length != (size_t)input[0] + 1) return -1;
    const size_t n = (size_t)input[0];
    int32_t values[MAX_LENGTH];
    for (size_t index = 0; index < n; ++index) {
        if (input[index + 1] < 0 || input[index + 1] > 127) return -1;
        values[index] = (int32_t)input[index + 1];
    }
    for (size_t index = 1; index < n; ++index) {
        const int32_t value = values[index];
        size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
    size_t max_count = 1;
    for (size_t factor = 2; factor <= n; ++factor) max_count *= factor;
    const size_t required = max_count * n;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;
    int32_t current[MAX_LENGTH];
    uint8_t used[MAX_LENGTH] = {0};
    size_t result_count = 0;
    generate(values, n, 0, current, used, output, &result_count);
    return (int64_t)result_count;
}
