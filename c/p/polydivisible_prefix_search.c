/* Count a bounded prefix tree of positive polydivisible numbers. */
#include <stddef.h>
#include <stdint.h>

#define MAX_BASE INT64_C(10)
#define MAX_DIGITS INT64_C(6)

static int64_t extend_prefix(int64_t prefix, int64_t digits,
                             int64_t base, int64_t max_digits) {
    int64_t count = 1;
    if (digits == max_digits) return count;
    const int64_t next_length = digits + 1;
    for (int64_t digit = 0; digit < base; ++digit) {
        const int64_t candidate = prefix * base + digit;
        if (candidate % next_length == 0)
            count += extend_prefix(candidate, next_length, base, max_digits);
    }
    return count;
}

int64_t polydivisible_prefix_search(const int64_t *input, size_t length) {
    if (input == NULL || length != 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t base = input[0];
    const int64_t max_digits = input[1];
    if (base < 2 || base > MAX_BASE || max_digits < 1 || max_digits > MAX_DIGITS) return -1;
    int64_t count = 0;
    for (int64_t first_digit = 1; first_digit < base; ++first_digit)
        count += extend_prefix(first_digit, 1, base, max_digits);
    return count;
}
