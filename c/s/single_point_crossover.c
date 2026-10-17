#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_PARENT_LENGTH 31
#define MAX_INPUT_LENGTH (2 + 2 * MAX_PARENT_LENGTH)

int64_t single_point_crossover(const double *input, size_t input_length,
                               double *output, size_t output_capacity) {
    if (input == NULL || input_length < 6 || input_length > MAX_INPUT_LENGTH) return -1;
    const double n_value = input[0];
    const double cut_value = input[1];
    if (!isfinite(n_value) || n_value < 2.0 || n_value > MAX_PARENT_LENGTH || floor(n_value) != n_value ||
        !isfinite(cut_value) || cut_value < 1.0 || cut_value > n_value - 1.0 || floor(cut_value) != cut_value) return -1;
    const size_t n = (size_t)n_value;
    const size_t cut = (size_t)cut_value;
    if (input_length != 2 + 2 * n) return -1;
    double first[MAX_PARENT_LENGTH], second[MAX_PARENT_LENGTH];
    for (size_t index = 0; index < n; ++index) {
        first[index] = input[2 + index];
        second[index] = input[2 + n + index];
        if (!isfinite(first[index]) || !isfinite(second[index])) return -1;
    }
    const size_t required = 2 * n;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t index = 0; index < n; ++index) {
        output[index] = index < cut ? first[index] : second[index];
        output[n + index] = index < cut ? second[index] : first[index];
    }
    return (int64_t)required;
}
