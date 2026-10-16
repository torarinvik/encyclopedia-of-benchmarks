#include <stddef.h>
#include <stdint.h>

enum { MAX_POINTS = 16 };

static double integer_power(double base, size_t exponent)
{
    double result = 1.0;
    for (size_t index = 0; index < exponent; ++index) result *= base;
    return result;
}

static uint64_t choose(size_t n, size_t k)
{
    if (k > n - k) k = n - k;
    uint64_t result = 1;
    for (size_t index = 1; index <= k; ++index)
        result = result * (n - k + index) / index;
    return result;
}

static int64_t round_scaled(double value)
{
    const double scaled = value * 1000000.0;
    return (int64_t)(scaled >= 0.0 ? scaled + 0.5 : scaled - 0.5);
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t bezier_curve(const int64_t *values, size_t length,
                     uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 4 || length > 34) return -1;
    const int64_t point_count_value = values[0], parameter_q = values[1];
    if (point_count_value < 1 || point_count_value > MAX_POINTS ||
        parameter_q < 0 || parameter_q > 1000000 ||
        length != 2 + 2 * (size_t)point_count_value) return -1;
    const size_t point_count = (size_t)point_count_value;
    for (size_t index = 2; index < length; ++index)
        if (values[index] < -1000000 || values[index] > 1000000) return -1;
    if (output == NULL || output_capacity < 32) return -2;

    const size_t degree = point_count - 1;
    const double t = (double)parameter_q / 1000000.0;
    double x = 0.0, y = 0.0, dx = 0.0, dy = 0.0;
    for (size_t index = 0; index < point_count; ++index) {
        const double weight = (double)choose(degree, index) *
            integer_power(1.0 - t, degree - index) * integer_power(t, index);
        x += weight * (double)values[2 + 2 * index];
        y += weight * (double)values[3 + 2 * index];
    }
    for (size_t index = 0; index < degree; ++index) {
        const double weight = (double)degree * (double)choose(degree - 1, index) *
            integer_power(1.0 - t, degree - 1 - index) * integer_power(t, index);
        dx += weight * (double)(values[4 + 2 * index] - values[2 + 2 * index]);
        dy += weight * (double)(values[5 + 2 * index] - values[3 + 2 * index]);
    }
    write_i64_le(output, 0, round_scaled(x));
    write_i64_le(output, 8, round_scaled(y));
    write_i64_le(output, 16, round_scaled(dx));
    write_i64_le(output, 24, round_scaled(dy));
    return 32;
}
