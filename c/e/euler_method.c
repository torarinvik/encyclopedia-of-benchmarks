#include <stddef.h>
#include <stdint.h>
#include <string.h>

static void put_f64_le(double value, uint8_t *output, size_t offset) {
    uint64_t bits; memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t euler_method(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length != 4 || input[0] < -8 || input[0] > 8 || input[1] < -8 || input[1] > 8 ||
        input[2] < 1 || input[2] > 4 || input[3] < 1 || input[3] > 16) return -1;
    const int64_t steps = input[3];
    const size_t required = 8 * ((size_t)steps + 1);
    if (!output || capacity < required) return -2;
    const double h = 1.0 / (double)(1 << input[2]);
    double x = (double)input[0], y = (double)input[1];
    put_f64_le(y, output, 0);
    for (int64_t step = 0; step < steps; ++step) {
        y = y + h * (x + y);
        x += h;
        put_f64_le(y, output, 8 * ((size_t)step + 1));
    }
    return (int64_t)required;
}
