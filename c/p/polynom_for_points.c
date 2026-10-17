#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MIN_POINTS 2
#define MAX_POINTS 8
#define MIN_X (-4)
#define MAX_X 4
#define MIN_Y (-25000)
#define MAX_Y 25000
#define MAX_COEFFICIENT 1000000.0
#define MAX_CONTRACT_BYTES 124
#define MAX_OUTPUT_BYTES 125

static void append_text(uint8_t *buffer, size_t *position, const char *text) {
    while (*text != '\0') buffer[(*position)++] = (uint8_t)*text++;
}

static void append_i64(uint8_t *buffer, size_t *position, int64_t value) {
    uint8_t digits[24];
    size_t count = 0;
    if (value < 0) {
        buffer[(*position)++] = '-';
        value = -value;
    }
    do {
        digits[count++] = (uint8_t)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count != 0) buffer[(*position)++] = digits[--count];
}

static void append_coefficient(uint8_t *buffer, size_t *position, double value) {
    if (value == 0.0) {
        if (signbit(value)) buffer[(*position)++] = '-';
        append_text(buffer, position, "0.0");
        return;
    }
    append_i64(buffer, position, (int64_t)value);
    append_text(buffer, position, ".0");
}

int64_t polynom_for_points(const int64_t *values, size_t length,
                           uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 1 || length > 1 + 2 * MAX_POINTS) return -1;
    const int64_t raw_n = values[0];
    if (raw_n < MIN_POINTS || raw_n > MAX_POINTS || length != 1 + 2 * (size_t)raw_n) return -1;
    const size_t n = (size_t)raw_n;
    int64_t xs[MAX_POINTS], ys[MAX_POINTS];
    double matrix[MAX_POINTS][MAX_POINTS] = {{0.0}};
    double vector[MAX_POINTS] = {0.0};
    for (size_t row = 0; row < n; ++row) {
        xs[row] = values[1 + 2 * row];
        ys[row] = values[2 + 2 * row];
        if (xs[row] < MIN_X || xs[row] > MAX_X || ys[row] < MIN_Y || ys[row] > MAX_Y) return -1;
        for (size_t previous = 0; previous < row; ++previous)
            if (xs[previous] == xs[row]) return -1;
        for (size_t column = 0; column < n; ++column) {
            int64_t power = 1;
            const size_t exponent = n - column - 1;
            for (size_t step = 0; step < exponent; ++step) power *= xs[row];
            matrix[row][column] = (double)power;
        }
        vector[row] = (double)ys[row];
    }

    for (size_t count = 0; count < n; ++count) {
        if (matrix[count][count] == 0.0) {
            size_t pivot_row = count + 1;
            for (size_t row = count + 2; row < n; ++row)
                if (fabs(matrix[row][count]) > fabs(matrix[pivot_row][count])) pivot_row = row;
            if (pivot_row >= n || matrix[pivot_row][count] == 0.0) return -1;
            for (size_t column = 0; column < n; ++column) {
                const double temporary = matrix[count][column];
                matrix[count][column] = matrix[pivot_row][column];
                matrix[pivot_row][column] = temporary;
            }
            const double temporary = vector[count];
            vector[count] = vector[pivot_row];
            vector[pivot_row] = temporary;
        }
        for (size_t row = 0; row < n; ++row) {
            if (row == count) continue;
            const double fraction = matrix[row][count] / matrix[count][count];
            for (size_t column = 0; column < n; ++column) {
                volatile double product = matrix[count][column] * fraction;
                matrix[row][column] -= product;
            }
            volatile double product = vector[count] * fraction;
            vector[row] -= product;
        }
    }

    double coefficients[MAX_POINTS];
    for (size_t index = 0; index < n; ++index) {
        coefficients[index] = vector[index] / matrix[index][index];
        if (!isfinite(coefficients[index]) || fabs(coefficients[index]) > MAX_COEFFICIENT ||
            trunc(coefficients[index]) != coefficients[index]) return -1;
    }

    uint8_t buffer[MAX_OUTPUT_BYTES];
    size_t position = 0;
    append_text(buffer, &position, "f(x)=");
    for (size_t index = 0; index < n; ++index) {
        if (index != 0) buffer[position++] = '+';
        append_text(buffer, &position, "x^");
        append_i64(buffer, &position, (int64_t)(n - index - 1));
        buffer[position++] = '*';
        append_coefficient(buffer, &position, coefficients[index]);
    }
    if (position > MAX_CONTRACT_BYTES) return -1;
    if (output == NULL || output_capacity < position) return -2;
    memcpy(output, buffer, position);
    return (int64_t)position;
}
