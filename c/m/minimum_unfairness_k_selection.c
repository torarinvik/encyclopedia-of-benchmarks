#include <stddef.h>
#include <stdint.h>

#define MUKS_MAX_N 64
#define MUKS_MIN_VALUE INT64_C(-1000000000)
#define MUKS_MAX_VALUE INT64_C(1000000000)

static void muks_sift_down(int64_t *values, size_t root, size_t end)
{
    while (root < end / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const int64_t temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

static void muks_heap_sort(int64_t *values, size_t length)
{
    for (size_t start = length / 2; start > 0; --start)
        muks_sift_down(values, start - 1, length);
    for (size_t end = length; end > 1; --end) {
        const int64_t temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        muks_sift_down(values, 0, end - 1);
    }
}

int64_t minimum_unfairness_k_selection(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 4 || length > MUKS_MAX_N + 2) return -1;
    const int64_t n_value = packed[0];
    const int64_t k_value = packed[1];
    if (n_value < 2 || n_value > MUKS_MAX_N || k_value < 2 || k_value > n_value
        || length != (size_t)n_value + 2) return -1;

    const size_t n = (size_t)n_value;
    const size_t k = (size_t)k_value;
    int64_t sorted[MUKS_MAX_N];
    for (size_t index = 0; index < n; ++index) {
        const int64_t value = packed[index + 2];
        if (value < MUKS_MIN_VALUE || value > MUKS_MAX_VALUE) return -1;
        sorted[index] = value;
    }

    muks_heap_sort(sorted, n);
    int64_t best = INT64_MAX;
    for (size_t first = 0; first + k <= n; ++first) {
        const int64_t width = sorted[first + k - 1] - sorted[first];
        if (width < best) best = width;
    }
    return best;
}
