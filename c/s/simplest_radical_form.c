#include <stddef.h>
#include <stdint.h>

#define MAX_RADICAND INT64_C(100000000)

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t simplest_radical_form(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length != 1) return -1;
    const int64_t original = values[0];
    if (original < 0 || original > MAX_RADICAND) return -1;
    if (output == NULL || capacity < 16) return -2;

    int64_t coefficient = 1, root_term = 1;
    if (original == 0) {
        root_term = 0;
    } else {
        int64_t remainder = original;
        for (int64_t factor = 2; factor * factor <= original; ++factor) {
            int64_t count = 0;
            while (remainder % factor == 0) { remainder /= factor; ++count; }
            for (int64_t power = 0; power < count / 2; ++power) coefficient *= factor;
            if (count % 2 != 0) root_term *= factor;
        }
        root_term *= remainder;
    }
    put_i64(output, 0, coefficient);
    put_i64(output, 8, root_term);
    return 16;
}
