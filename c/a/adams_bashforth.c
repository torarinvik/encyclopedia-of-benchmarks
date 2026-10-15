/* Bounded Adams-Bashforth methods for y' = x + y on a quarter-step grid. */
#include <stddef.h>
#include <stdint.h>

static size_t append_integer(int64_t value, uint8_t *out, size_t position)
{
    uint8_t digits[24];
    size_t count = 0;
    if (value < 0) { out[position++] = '-'; value = -value; }
    do { digits[count++] = (uint8_t)(value % 10); value /= 10; } while (value > 0);
    while (count > 0) out[position++] = (uint8_t)('0' + digits[--count]);
    return position;
}

int64_t adams_bashforth(const int64_t *values, size_t length, uint8_t *output,
                        size_t output_capacity)
{
    if (values == NULL || length < 4) return -1;
    const int64_t order_arg = values[0], steps_arg = values[1];
    if (order_arg < 2 || order_arg > 5 || steps_arg < 1 || steps_arg > 4 ||
        length != (size_t)order_arg + 2) return -1;
    const size_t order = (size_t)order_arg, steps = (size_t)steps_arg;
    double x[14], y[14];
    for (size_t i = 0; i < order; ++i) {
        if (values[i + 2] < -100000 || values[i + 2] > 100000) return -1;
        x[i] = (double)i * 0.25;
        y[i] = (double)values[i + 2] / 100000.0;
    }
    static const int64_t c2[] = {3, -1};
    static const int64_t c3[] = {23, -16, 5};
    static const int64_t c4[] = {55, -59, 37, -9};
    static const int64_t c5[] = {1901, -2774, -2616, -1274, 251};
    const int64_t *coefficients = order == 2 ? c2 : order == 3 ? c3 : order == 4 ? c4 : c5;
    const int64_t denominator = order == 2 ? 2 : order == 3 ? 12 : order == 4 ? 24 : 720;
    const size_t iterations = steps + ((order == 3 || order == 5) ? 1 : 0);
    size_t count = order;
    for (size_t iteration = 0; iteration < iterations; ++iteration) {
        double weighted = 0.0;
        for (size_t offset = 0; offset < order; ++offset) {
            const size_t index = count - 1 - offset;
            weighted += (double)coefficients[offset] * (x[index] + y[index]);
        }
        y[count] = y[count - 1] + (0.25 / (double)denominator) * weighted;
        x[count] = x[count - 1] + 0.25;
        ++count;
    }
    uint8_t encoded[256];
    size_t position = 0;
    for (size_t i = 0; i < count; ++i) {
        if (i != 0) encoded[position++] = ',';
        position = append_integer((int64_t)(y[i] * 1000000.0), encoded, position);
    }
    if (output == NULL || output_capacity < position) return -2;
    for (size_t i = 0; i < position; ++i) output[i] = encoded[i];
    return (int64_t)position;
}
