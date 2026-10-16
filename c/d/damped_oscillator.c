#include <stddef.h>
#include <stdint.h>
#include <string.h>

static void put_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t damped_oscillator(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 5) return -1;
    if (input[0] < 1 || input[0] > 1024 || input[1] < 0 || input[1] > 1024 ||
        input[2] < -1024 || input[2] > 1024 || input[3] < -1024 || input[3] > 1024 ||
        input[4] < 1 || input[4] > 1024) return -1;
    if (output == NULL || capacity < 16) return -2;
    const double omega0 = (double)input[0] / 1024.0;
    const double gamma = (double)input[1] / 1024.0;
    const double x = (double)input[2] / 1024.0;
    const double v = (double)input[3] / 1024.0;
    const double dt = (double)input[4] / 1024.0;
    const double acceleration = -2.0 * gamma * v - omega0 * omega0 * x;
    const double x_next = x + dt * v;
    const double v_next = v + dt * acceleration;
    put_f64_le(output, 0, x_next);
    put_f64_le(output, 8, v_next);
    return 16;
}
