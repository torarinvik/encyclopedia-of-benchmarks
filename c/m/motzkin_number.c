#include <stddef.h>
#include <stdint.h>

enum { MAX_PARSEABLE_LENGTH = 2, MAX_N = 30 };

static int64_t motzkin_number_value(int64_t n) {
    int64_t values[MAX_N + 1] = {0};
    values[0] = 1;
    if (n >= 1) values[1] = 1;
    for (int64_t size = 2; size <= n; ++size) {
        int64_t total = values[size - 1];
        for (int64_t left = 0; left <= size - 2; ++left)
            total += values[left] * values[size - 2 - left];
        values[size] = total;
    }
    return values[n];
}

int64_t motzkin_number(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 0 || input[0] > MAX_N) return -1;
    return motzkin_number_value(input[0]);
}
