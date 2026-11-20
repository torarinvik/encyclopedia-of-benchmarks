#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>

#define MAX_N 256
#define MAX_VALID_LENGTH 257
#define MAX_PARSEABLE_LENGTH 258

static int descending_i64(const void *left, const void *right) {
    int64_t a = *(const int64_t *)left;
    int64_t b = *(const int64_t *)right;
    return (b > a) - (b < a);
}

int64_t erdos_gallai_graphical_sequence(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    int64_t n_word = input[0];
    if (n_word < 0 || n_word > MAX_N) return -1;
    size_t n = (size_t)n_word;
    if (length != n + 1 || length > MAX_VALID_LENGTH) return -1;

    int64_t degrees[MAX_N];
    int64_t prefix[MAX_N + 1] = {0};
    int64_t sum = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t degree = input[i + 1];
        if (degree < 0 || degree >= n_word) return -1;
        degrees[i] = degree;
        sum += degree;
    }
    if ((sum & 1) != 0) return 0;
    if (n == 0) return 1;

    qsort(degrees, n, sizeof(degrees[0]), descending_i64);
    for (size_t i = 0; i < n; ++i) prefix[i + 1] = prefix[i] + degrees[i];

    for (size_t k = 1; k <= n; ++k) {
        size_t low = k, high = n;
        while (low < high) {
            size_t mid = low + (high - low) / 2;
            if (degrees[mid] >= (int64_t)k) low = mid + 1;
            else high = mid;
        }
        size_t split = low;
        int64_t rhs = (int64_t)k * (int64_t)(k - 1)
                    + (int64_t)(split - k) * (int64_t)k
                    + (prefix[n] - prefix[split]);
        if (prefix[k] > rhs) return 0;
    }
    return 1;
}
