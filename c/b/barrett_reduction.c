#include <stddef.h>
#include <stdint.h>

enum { MAX_MODULUS = 65535, MAX_VALUES = 12, MAX_LENGTH = 15 };
static const int64_t RADIX = INT64_C(4294967296);

int64_t barrett_reduction(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_LENGTH) return -1;
    const int64_t modulus = input[0];
    const int64_t count_value = input[1];
    if (modulus < 2 || modulus > MAX_MODULUS || count_value < 0 || count_value > MAX_VALUES) return -1;
    const size_t count = (size_t)count_value;
    if (length != 2 + count) return -1;
    const int64_t square_bound = modulus * modulus;
    for (size_t i = 0; i < count; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= square_bound) return -1;

    const int64_t reciprocal = RADIX / modulus;
    int64_t checksum = 0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t value = input[2 + i];
        const int64_t quotient = (value * reciprocal) / RADIX;
        int64_t remainder = value - quotient * modulus;
        if (remainder >= modulus) remainder -= modulus;
        checksum += (int64_t)(i + 1) * (remainder + 1);
    }
    return checksum;
}
