#include <stddef.h>
#include <stdint.h>

int64_t select_bits(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > 3) {
        return -1;
    }

    const int64_t number = values[0];
    if (number < 0 || number > INT64_C(9007199254740991)) {
        return -1;
    }

    const int64_t first = length >= 2 ? values[1] : 1;
    const int64_t last = length >= 3 ? values[2] : 53;
    if (first < 1 || first > 53 || last < 1 || last > 53) {
        return -1;
    }

    const uint64_t modulus = UINT64_C(1) << (unsigned)last;
    return (int64_t)(((uint64_t)number % modulus) >> (unsigned)(first - 1));
}
