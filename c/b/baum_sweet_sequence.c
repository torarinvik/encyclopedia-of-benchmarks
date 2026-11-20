/* Pack a bounded prefix of OEIS A086747 using a zero-run parity automaton. */
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT INT64_C(63)

static int64_t baum_sweet_term(int64_t number) {
    if (number == 0) return 0;
    int64_t mask = 1;
    while (mask <= number / 2) mask *= 2;
    int odd_zero_run = 0;
    while (mask > 0) {
        if ((number & mask) != 0) {
            if (odd_zero_run) return 0;
            odd_zero_run = 0;
        } else {
            odd_zero_run ^= 1;
        }
        mask /= 2;
    }
    return odd_zero_run == 0 ? 1 : 0;
}

int64_t baum_sweet_sequence(const int64_t *input, size_t length) {
    if (input == NULL || length != 1) return -1;
    const int64_t count = input[0];
    if (count < 0 || count > MAX_COUNT) return -1;
    int64_t packed = 0;
    int64_t bit = 1;
    for (int64_t index = 0; index < count; ++index) {
        if (baum_sweet_term(index) != 0) packed += bit;
        if (index + 1 < count) bit *= 2;
    }
    return packed;
}
