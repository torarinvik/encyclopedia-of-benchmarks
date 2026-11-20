#include <stddef.h>
#include <stdint.h>

enum { MAX_LIMIT = 100000, MAX_PARSEABLE_LENGTH = 2, WORD_COUNT = 1563 };

static int64_t digit_sum10(int64_t value) {
    int64_t sum = 0;
    while (value > 0) {
        sum += value % 10;
        value /= 10;
    }
    return sum;
}

int64_t self_number_count_sieve(const int64_t *input, size_t length) {
    if (input == NULL || length < 1U || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t limit = input[0];
    if (length != 1U || limit < 1 || limit > MAX_LIMIT) return -1;

    uint64_t generated[WORD_COUNT] = {0};
    for (int64_t source = 1; source <= limit; ++source) {
        const int64_t target = source + digit_sum10(source);
        if (target <= limit) generated[(size_t)(target >> 6)] |= UINT64_C(1) << (unsigned)(target & 63);
    }
    int64_t count = 0;
    for (int64_t value = 1; value <= limit; ++value) {
        if ((generated[(size_t)(value >> 6)] & (UINT64_C(1) << (unsigned)(value & 63))) == 0) ++count;
    }
    return count;
}
