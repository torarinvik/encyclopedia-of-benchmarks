#include <stddef.h>
#include <stdint.h>

enum { MAX_INDEX = 128, MAX_PARSEABLE_LENGTH = 2 };

int64_t hofstadter_q_sequence(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_INDEX) return -1;

    const size_t target = (size_t)input[0];
    int64_t q[MAX_INDEX + 1] = {0};
    q[1] = 1;
    if (target >= 2) q[2] = 1;
    for (size_t n = 3; n <= target; ++n) {
        const int64_t left = (int64_t)n - q[n - 1];
        const int64_t right = (int64_t)n - q[n - 2];
        if (left < 1 || right < 1 || left >= (int64_t)n || right >= (int64_t)n) return -1;
        q[n] = q[(size_t)left] + q[(size_t)right];
    }
    return q[target];
}
