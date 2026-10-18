#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_CITIES 2
#define MAX_CITIES 8
#define MAX_INPUT_LENGTH 17
#define MAX_OUTPUT_LENGTH 11
#define COORDINATE_LIMIT 16.0

int64_t travelling_salesman_python_bruteforce(const double *input, size_t input_len,
                                               double *output, size_t output_capacity) {
    if (input == NULL || input_len < 3 || input_len > MAX_INPUT_LENGTH) return -1;
    const double raw_count = input[0];
    if (!isfinite(raw_count) || raw_count < MIN_CITIES || raw_count > MAX_CITIES ||
        raw_count != floor(raw_count)) return -1;
    const size_t city_count = (size_t)raw_count;
    if (input_len != 1 + 2 * city_count) return -1;

    double x[MAX_CITIES], y[MAX_CITIES];
    for (size_t i = 0; i < city_count; ++i) {
        x[i] = input[1 + 2 * i];
        y[i] = input[2 + 2 * i];
        if (!isfinite(x[i]) || !isfinite(y[i]) || fabs(x[i]) > COORDINATE_LIMIT ||
            fabs(y[i]) > COORDINATE_LIMIT || x[i] != floor(x[i]) || y[i] != floor(y[i])) return -1;
    }

    const size_t permutation_len = city_count - 1;
    size_t order[MAX_CITIES - 1];
    for (size_t i = 0; i < permutation_len; ++i) order[i] = i + 1;
    size_t best_order[MAX_CITIES - 1];
    double best_distance = INFINITY;
    for (;;) {
        double total = 0.0;
        size_t previous = 0;
        for (size_t i = 0; i <= permutation_len; ++i) {
            const size_t next = i == permutation_len ? 0 : order[i];
            const double dx = x[next] - x[previous];
            const double dy = y[next] - y[previous];
            total += sqrt(dx * dx + dy * dy);
            previous = next;
        }
        if (total < best_distance) {
            best_distance = total;
            for (size_t i = 0; i < permutation_len; ++i) best_order[i] = order[i];
        }

        size_t i = permutation_len;
        while (i > 1 && order[i - 2] >= order[i - 1]) --i;
        if (i <= 1) break;
        const size_t pivot = i - 2;
        size_t j = permutation_len - 1;
        while (order[j] <= order[pivot]) --j;
        const size_t temp = order[pivot];
        order[pivot] = order[j];
        order[j] = temp;
        size_t left = i - 1, right = permutation_len - 1;
        while (left < right) {
            const size_t value = order[left];
            order[left++] = order[right];
            order[right--] = value;
        }
    }

    double result[MAX_OUTPUT_LENGTH];
    const size_t path_len = city_count + 1;
    result[0] = (double)path_len;
    result[1] = 0.0;
    for (size_t i = 0; i < permutation_len; ++i) result[2 + i] = (double)best_order[i];
    result[path_len] = 0.0;
    result[path_len + 1] = best_distance;
    const size_t required = city_count + 3;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t i = 0; i < required; ++i) output[i] = result[i];
    return (int64_t)required;
}
