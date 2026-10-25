#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

#define INVALID_RESULT INT64_C(-1)
#define OUTPUT_ERROR INT64_C(-2)
#define REQUIRED_BYTES 24u
#define MAX_OUTPUT_BYTES 24u
#define NEWTON_EPSILON 5.0e-6
#define MAX_NEWTON_ITERATIONS 40

static double absolute_value(double value) { return value < 0.0 ? -value : value; }

static double horner_value_and_derivative(int degree, const double *coefficients,
                                          double x, double *derivative) {
    double value = coefficients[degree];
    double slope = value;
    for (int j = degree - 1; j >= 1; --j) {
        value = x * value + coefficients[j];
        slope = x * slope + value;
    }
    value = x * value + coefficients[0];
    *derivative = slope;
    return value;
}

static double newton_root(int degree, const double *coefficients, double lower, double upper) {
    if (upper < lower) { double temporary = lower; lower = upper; upper = temporary; }
    double previous = lower;
    double current = (lower + upper) / 2.0;
    int iterations = 0;
    while (absolute_value(current - previous) / absolute_value(current) > NEWTON_EPSILON &&
           iterations <= MAX_NEWTON_ITERATIONS) {
        previous = current;
        double derivative = 0.0;
        double value = horner_value_and_derivative(degree, coefficients, current, &derivative);
        current = current - value / derivative;
        ++iterations;
    }
    return current;
}

static void store_f64_le(double value, uint8_t *output, size_t offset) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8u * i));
}

static size_t solve(uint8_t *staged) {
    const double original[4] = {4.0, -4.0, -1.0, 1.0};
    double coefficients[4];
    memcpy(coefficients, original, sizeof(coefficients));
    double upper = 0.0;
    for (int i = 0; i <= 3; ++i) upper += absolute_value(coefficients[i]);
    upper /= absolute_value(coefficients[3]);
    const double lower = -upper - 1.0;

    const double first_root = newton_root(3, coefficients, lower, upper);
    double deflated[3] = {0.0, 0.0, 0.0};
    deflated[2] = coefficients[3];
    for (int i = 1; i >= 0; --i) deflated[i] = deflated[i + 1] * first_root + coefficients[i + 1];

    const double discriminant = deflated[1] * deflated[1] - 4.0 * deflated[2] * deflated[0];
    const double plus_root = (-deflated[1] + sqrt(discriminant)) / (2.0 * deflated[2]);
    const double minus_root = (-deflated[1] - sqrt(discriminant)) / (2.0 * deflated[2]);

    /* The original source refines both quadratic roots against the cubic. */
    const double refined_plus = newton_root(3, original, plus_root - 0.5, plus_root + 0.5);
    const double refined_minus = newton_root(3, original, minus_root - 0.5, minus_root + 0.5);
    store_f64_le(first_root, staged, 0);
    store_f64_le(refined_plus, staged, 8);
    store_f64_le(refined_minus, staged, 16);
    return REQUIRED_BYTES;
}

int64_t prolangs_c_allroots(const int64_t *values, size_t length,
                            uint8_t *output, size_t output_capacity) {
    if (values == NULL || length != 4 || values[0] != 4 || values[1] != -4 ||
        values[2] != -1 || values[3] != 1) return INVALID_RESULT;
    if (output == NULL || output_capacity < REQUIRED_BYTES) return OUTPUT_ERROR;
    uint8_t staged[MAX_OUTPUT_BYTES];
    const size_t used = solve(staged);
    memcpy(output, staged, used);
    return (int64_t)used;
}
