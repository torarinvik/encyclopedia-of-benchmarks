#include <stddef.h>
#include <stdint.h>

enum { MIN_BASE = 3, MAX_BASE = 16, MAX_DIGITS = 10, MAX_LIMIT = 100000,
       MAX_PARSEABLE_LENGTH = 3, MAX_QUEUE = 70000 };

static int is_prime(int64_t value) {
    if (value < 2) return 0;
    if (value % 2 == 0) return value == 2;
    for (int64_t divisor = 3; divisor * divisor <= value; divisor += 2)
        if (value % divisor == 0) return 0;
    return 1;
}

int64_t left_truncatable_prime_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t base = input[0], digits = input[1];
    if (length != 2 || base < MIN_BASE || base > MAX_BASE || digits < 1 || digits > MAX_DIGITS) return -1;
    int64_t limit = 1;
    for (int64_t i = 0; i < digits; ++i) limit *= base;
    if (limit > MAX_LIMIT) return -1;

    int64_t queue[MAX_QUEUE];
    size_t end = 0;
    for (int64_t value = 2; value < base; ++value)
        if (is_prime(value)) queue[end++] = value;
    int64_t best = queue[end - 1];
    size_t level_start = 0, level_end = end;
    int64_t place = base;
    for (int64_t width = 1; width < digits && level_start < level_end; ++width) {
        for (size_t index = level_start; index < level_end; ++index) {
            const int64_t suffix = queue[index];
            for (int64_t leading = 1; leading < base; ++leading) {
                const int64_t candidate = leading * place + suffix;
                if (is_prime(candidate)) {
                    if (end >= MAX_QUEUE) return -1;
                    queue[end++] = candidate;
                    if (candidate > best) best = candidate;
                }
            }
        }
        level_start = level_end;
        level_end = end;
        place *= base;
    }
    return best;
}
