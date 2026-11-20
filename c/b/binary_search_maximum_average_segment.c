/* Clean-room integer-threshold maximum-average segment profile. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_INPUT 35
#define SCALE INT64_C(1000)
#define INVALID_RESULT INT64_C(-1000001)

static int feasible(const int64_t *input, size_t n, size_t minimum_length,
                    int64_t threshold)
{
    int64_t prefix[MAX_N + 1];
    prefix[0] = 0;
    for (size_t index = 0; index < n; ++index) {
        prefix[index + 1] = prefix[index] + SCALE * input[index + 2] - threshold;
    }
    int64_t minimum_prefix = INT64_MAX;
    for (size_t end = minimum_length; end <= n; ++end) {
        const size_t eligible_start = end - minimum_length;
        if (prefix[eligible_start] < minimum_prefix) minimum_prefix = prefix[eligible_start];
        if (prefix[end] >= minimum_prefix) return 1;
    }
    return 0;
}

int64_t binary_search_maximum_average_segment(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return INVALID_RESULT;
    const int64_t n_value = input[0];
    const int64_t minimum_value = input[1];
    if (n_value < 1 || n_value > MAX_N || minimum_value < 1 || minimum_value > n_value
        || length != (size_t)(n_value + 2)) return INVALID_RESULT;
    const size_t n = (size_t)n_value;
    for (size_t index = 0; index < n; ++index) {
        if (input[index + 2] < -1000 || input[index + 2] > 1000) return INVALID_RESULT;
    }

    int64_t low = -INT64_C(1000000);
    int64_t high = INT64_C(1000001);
    while (high - low > 1) {
        const int64_t middle = low + (high - low) / 2;
        if (feasible(input, n, (size_t)minimum_value, middle)) low = middle;
        else high = middle;
    }
    return low;
}
