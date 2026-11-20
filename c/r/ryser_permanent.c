#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 8
#define MAX_INPUT_LENGTH (1 + MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT INT64_MIN

static unsigned bit_count(unsigned value) {
    unsigned count = 0;
    while (value != 0) {
        count += value & 1U;
        value >>= 1U;
    }
    return count;
}

int64_t ryser_permanent(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > MAX_DIMENSION) return INVALID_RESULT;
    const unsigned n = (unsigned)input[0];
    if (length != (size_t)(1 + n * n)) return INVALID_RESULT;

    for (unsigned index = 0; index < n * n; ++index) {
        if (input[1 + index] < -4 || input[1 + index] > 4) return INVALID_RESULT;
    }

    int64_t row_sums[MAX_DIMENSION] = {0};
    int64_t total = 0;
    unsigned previous_gray = 0;
    const unsigned subset_count = 1U << n;
    for (unsigned ordinal = 0; ordinal < subset_count; ++ordinal) {
        const unsigned gray = ordinal ^ (ordinal >> 1U);
        if (ordinal != 0) {
            const unsigned changed = gray ^ previous_gray;
            unsigned column = 0;
            while (((changed >> column) & 1U) == 0U) ++column;
            const int64_t direction = (gray & changed) != 0 ? 1 : -1;
            for (unsigned row = 0; row < n; ++row) {
                row_sums[row] += direction * input[1 + row * n + column];
            }
        }

        int64_t product = 1;
        for (unsigned row = 0; row < n; ++row) product *= row_sums[row];
        if (((n + bit_count(gray)) & 1U) != 0U) product = -product;
        total += product;
        previous_gray = gray;
    }
    return total;
}
