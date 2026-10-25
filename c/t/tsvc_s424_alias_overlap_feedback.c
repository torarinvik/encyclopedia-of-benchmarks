/* Clean-room port of TSVC s424; provenance and rights are in package README. */
#include <stddef.h>
#include <stdint.h>

enum { MIN_N = 66, MAX_N = 192, X_LENGTH = MAX_N + 63, MAX_INPUT_LENGTH = MAX_N + 64 };

int64_t tsvc_s424_alias_overlap_feedback(const int64_t *input, size_t length) {
    if (input == NULL || length < MIN_N + 64 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < MIN_N || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 64) return -1;
    int64_t a[MAX_N];
    int64_t x[X_LENGTH] = {0};
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[1 + i];
        if (a[i] < 0 || a[i] > 10) return -1;
    }
    for (size_t i = 0; i < 63; ++i) {
        x[i] = input[1 + n + i];
        if (x[i] < 0 || x[i] > 10) return -1;
    }
    /* xx is array+63; xx[i+1] aliases array[i+64]. Keep ascending order. */
    for (size_t i = 0; i < n - 1; ++i) x[i + 64] = x[i] + a[i];
    int64_t checksum = 0;
    for (size_t i = 0; i < n; ++i) checksum += x[63 + i];
    return checksum;
}
