/* Find the first partition number divisible by the requested modulus. */
#include <stdint.h>

enum { MAX_MODULUS = 1000000, MAX_INDEX = 55374 };

static int64_t positive_mod(int64_t value, int64_t modulus)
{
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

int64_t problem78(int64_t modulus)
{
    if (modulus < 1 || modulus > MAX_MODULUS) return -1;
    uint32_t partitions[MAX_INDEX + 1] = {1};
    for (int64_t n = 1; n <= MAX_INDEX; ++n) {
        int64_t value = 0;
        for (int64_t j = 1;; ++j) {
            const int64_t first = (3 * j * j - j) / 2;
            if (first > n) break;
            const int64_t sign = j % 2 == 0 ? -1 : 1;
            value = positive_mod(value + sign * partitions[n - first], modulus);
            const int64_t second = first + j;
            if (second > n) break;
            value = positive_mod(value + sign * partitions[n - second], modulus);
        }
        if (value == 0) return n;
        partitions[n] = (uint32_t)value;
    }
    return -1;
}
