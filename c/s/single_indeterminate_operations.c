#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum {
    MAX_DEGREE = 8,
    MAX_COEFFICIENTS = MAX_DEGREE + 1,
    MAX_INPUT_LENGTH = 22,
    MAX_OUTPUT_ELEMENTS = 2 * MAX_DEGREE + 1
};

enum {
    OP_ADD = 0,
    OP_SUBTRACT = 1,
    OP_MULTIPLY = 2,
    OP_EVALUATE = 3,
    OP_DERIVATIVE = 4,
    OP_INTEGRAL = 5
};

static int finite_value(double value)
{
    return isfinite(value) != 0;
}

static int exact_integer_in_range(double value, int minimum, int maximum, int *result)
{
    if (!finite_value(value) || value < (double)minimum || value > (double)maximum ||
        value != trunc(value)) return 0;
    *result = (int)value;
    return 1;
}

static double rounded_add(double left, double right)
{
    volatile double result = left + right;
    return result;
}

static double rounded_multiply(double left, double right)
{
    volatile double result = left * right;
    return result;
}

static double rounded_divide(double left, double right)
{
    volatile double result = left / right;
    return result;
}

static int read_polynomial(const double *values, size_t length, size_t *cursor,
                           int *degree, double coefficients[MAX_COEFFICIENTS])
{
    if (*cursor >= length ||
        !exact_integer_in_range(values[*cursor], 0, MAX_DEGREE, degree)) return 0;
    ++*cursor;

    const size_t count = (size_t)(*degree + 1);
    if (*cursor > length || count > length - *cursor) return 0;
    for (size_t index = 0; index < count; ++index) {
        const double coefficient = values[*cursor + index];
        if (!finite_value(coefficient) || coefficient < -10.0 || coefficient > 10.0)
            return 0;
        coefficients[index] = coefficient;
    }
    *cursor += count;
    return 1;
}

static void add_polynomials(int degree_a, const double *a, int degree_b, const double *b,
                            double *result, size_t *result_count)
{
    const double *base;
    const double *other;
    int base_degree;
    int other_degree;
    if (degree_a > degree_b) {
        base = a;
        other = b;
        base_degree = degree_a;
        other_degree = degree_b;
    } else {
        base = b;
        other = a;
        base_degree = degree_b;
        other_degree = degree_a;
    }

    for (int index = 0; index <= base_degree; ++index) result[index] = base[index];
    for (int index = 0; index <= other_degree; ++index)
        result[index] = rounded_add(result[index], other[index]);
    *result_count = (size_t)(base_degree + 1);
}

static void multiply_polynomials(int degree_a, const double *a, int degree_b, const double *b,
                                 double *result, size_t *result_count)
{
    const int degree = degree_a + degree_b;
    for (int index = 0; index <= degree; ++index) result[index] = 0.0;
    for (int i = 0; i <= degree_a; ++i) {
        for (int j = 0; j <= degree_b; ++j) {
            const double product = rounded_multiply(a[i], b[j]);
            result[i + j] = rounded_add(result[i + j], product);
        }
    }
    *result_count = (size_t)(degree + 1);
}

int64_t single_indeterminate_operations(const double *values, size_t length,
                                        double *output, size_t output_capacity)
{
    if (values == NULL || length < 3u || length > MAX_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index)
        if (!finite_value(values[index])) return -1;

    int operation;
    if (!exact_integer_in_range(values[0], OP_ADD, OP_INTEGRAL, &operation)) return -1;

    double coefficients_a[MAX_COEFFICIENTS] = {0.0};
    double coefficients_b[MAX_COEFFICIENTS] = {0.0};
    int degree_a;
    size_t cursor = 1u;
    if (!read_polynomial(values, length, &cursor, &degree_a, coefficients_a)) return -1;

    int degree_b = 0;
    if (operation <= OP_MULTIPLY &&
        !read_polynomial(values, length, &cursor, &degree_b, coefficients_b)) return -1;

    double parameter = 0.0;
    if (operation == OP_DERIVATIVE) {
        if (cursor != length) return -1;
    } else if (operation == OP_EVALUATE || operation == OP_INTEGRAL) {
        if (cursor + 1u != length) return -1;
        parameter = values[cursor];
        const double minimum = operation == OP_EVALUATE ? -2.0 : -10.0;
        const double maximum = operation == OP_EVALUATE ? 2.0 : 10.0;
        if (parameter < minimum || parameter > maximum) return -1;
    } else if (cursor != length) {
        return -1;
    }

    double result[MAX_OUTPUT_ELEMENTS] = {0.0};
    size_t result_count = 0u;
    if (operation == OP_ADD) {
        add_polynomials(degree_a, coefficients_a, degree_b, coefficients_b,
                        result, &result_count);
    } else if (operation == OP_SUBTRACT) {
        double negated[MAX_COEFFICIENTS] = {0.0};
        const double minus_one = -1.0;
        for (int index = 0; index <= degree_b; ++index) {
            const double product = rounded_multiply(coefficients_b[index], minus_one);
            negated[index] = rounded_add(negated[index], product);
        }
        add_polynomials(degree_a, coefficients_a, degree_b, negated, result, &result_count);
    } else if (operation == OP_MULTIPLY) {
        multiply_polynomials(degree_a, coefficients_a, degree_b, coefficients_b,
                             result, &result_count);
    } else if (operation == OP_EVALUATE) {
        double accumulated = 0.0;
        for (int index = 0; index <= degree_a; ++index) {
            const double power = pow(parameter, (double)index);
            const double term = rounded_multiply(coefficients_a[index], power);
            accumulated = rounded_add(accumulated, term);
        }
        result[0] = accumulated;
        result_count = 1u;
    } else if (operation == OP_DERIVATIVE) {
        for (int index = 0; index < degree_a; ++index)
            result[index] = rounded_multiply(coefficients_a[index + 1], (double)(index + 1));
        result_count = (size_t)degree_a;
    } else {
        result[0] = parameter;
        for (int index = 0; index <= degree_a; ++index)
            result[index + 1] = rounded_divide(coefficients_a[index], (double)(index + 1));
        result_count = (size_t)(degree_a + 2);
    }

    if (result_count > MAX_OUTPUT_ELEMENTS) return -1;
    for (size_t index = 0; index < result_count; ++index)
        if (!finite_value(result[index])) return -1;

    if (output == NULL || output_capacity < result_count) return -2;
    for (size_t index = 0; index < result_count; ++index) output[index] = result[index];
    return (int64_t)result_count;
}
