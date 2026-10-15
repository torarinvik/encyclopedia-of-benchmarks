#include <stddef.h>
#include <stdint.h>

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)((bits >> (8 * byte)) & 0xffu);
    }
}

int64_t farey_approximation(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length != 2) return -1;
    const int64_t decimal_millionths = values[0];
    const int64_t repeat = values[1];
    if (decimal_millionths < 1 || decimal_millionths > 999999 || repeat < 1 || repeat > 20) return -1;
    if (output == NULL || capacity < 16) return -2;

    const double decimal = (double)decimal_millionths / 1000000.0;
    int64_t a = 0, b = 1, c = 1, d = 1;
    int64_t numerator = 0, denominator = 0;
    for (int64_t i = 0; i < repeat; ++i) {
        numerator = a + c;
        denominator = b + d;
        if (decimal > (double)numerator / (double)denominator) {
            a = numerator;
            b = denominator;
        } else {
            c = numerator;
            d = denominator;
        }
    }
    store_i64_le(output, 0, numerator);
    store_i64_le(output, 8, denominator);
    return 16;
}
