#include <stddef.h>
#include <stdint.h>

enum { MAX_INDEX = 8192, MAX_PARSEABLE_LENGTH = 2 };

int64_t hofstadter_conway_10000_sequence(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 2 || input[0] > MAX_INDEX) return -1;

    const size_t target = (size_t)input[0];
    int64_t a[MAX_INDEX + 1] = {0};
    a[1] = 1;
    a[2] = 1;
    for (size_t n = 3; n <= target; ++n) {
        const int64_t previous = a[n - 1];
        const int64_t other = (int64_t)n - previous;
        if (previous < 1 || previous >= (int64_t)n || other < 1 || other >= (int64_t)n) return -1;
        a[n] = a[(size_t)previous] + a[(size_t)other];
    }
    return a[target];
}
