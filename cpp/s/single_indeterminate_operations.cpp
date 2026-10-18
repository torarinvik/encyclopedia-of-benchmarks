#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_degree = 8;
constexpr std::size_t max_coefficients = static_cast<std::size_t>(max_degree + 1);
constexpr std::size_t max_input_length = 22;
constexpr std::size_t max_output_elements = 2 * static_cast<std::size_t>(max_degree) + 1;

enum Operation : int {
    op_add = 0,
    op_subtract = 1,
    op_multiply = 2,
    op_evaluate = 3,
    op_derivative = 4,
    op_integral = 5
};

bool finite_value(double value) noexcept { return std::isfinite(value); }

bool exact_integer_in_range(double value, int minimum, int maximum, int& result) noexcept
{
    if (!finite_value(value) || value < static_cast<double>(minimum) ||
        value > static_cast<double>(maximum) || std::trunc(value) != value) return false;
    result = static_cast<int>(value);
    return true;
}

double rounded_add(double left, double right) noexcept
{
    volatile double result = left + right;
    return result;
}

double rounded_multiply(double left, double right) noexcept
{
    volatile double result = left * right;
    return result;
}

double rounded_divide(double left, double right) noexcept
{
    volatile double result = left / right;
    return result;
}

bool read_polynomial(const double* values, std::size_t length, std::size_t& cursor,
                     int& degree, double* coefficients) noexcept
{
    if (cursor >= length || !exact_integer_in_range(values[cursor], 0, max_degree, degree))
        return false;
    ++cursor;
    const std::size_t count = static_cast<std::size_t>(degree + 1);
    if (cursor > length || count > length - cursor) return false;
    for (std::size_t index = 0; index < count; ++index) {
        const double coefficient = values[cursor + index];
        if (!finite_value(coefficient) || coefficient < -10.0 || coefficient > 10.0)
            return false;
        coefficients[index] = coefficient;
    }
    cursor += count;
    return true;
}

void add_polynomials(int degree_a, const double* a, int degree_b, const double* b,
                     double* result, std::size_t& result_count) noexcept
{
    const double* base;
    const double* other;
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
    result_count = static_cast<std::size_t>(base_degree + 1);
}

void multiply_polynomials(int degree_a, const double* a, int degree_b, const double* b,
                          double* result, std::size_t& result_count) noexcept
{
    const int degree = degree_a + degree_b;
    for (int index = 0; index <= degree; ++index) result[index] = 0.0;
    for (int i = 0; i <= degree_a; ++i) {
        for (int j = 0; j <= degree_b; ++j) {
            const double product = rounded_multiply(a[i], b[j]);
            result[i + j] = rounded_add(result[i + j], product);
        }
    }
    result_count = static_cast<std::size_t>(degree + 1);
}
} // namespace

extern "C" std::int64_t single_indeterminate_operations(const double* values,
                                                         std::size_t length,
                                                         double* output,
                                                         std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 3 || length > max_input_length) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (!finite_value(values[index])) return -1;

    int operation;
    if (!exact_integer_in_range(values[0], op_add, op_integral, operation)) return -1;

    double coefficients_a[max_coefficients]{};
    double coefficients_b[max_coefficients]{};
    int degree_a;
    std::size_t cursor = 1;
    if (!read_polynomial(values, length, cursor, degree_a, coefficients_a)) return -1;

    int degree_b = 0;
    if (operation <= op_multiply &&
        !read_polynomial(values, length, cursor, degree_b, coefficients_b)) return -1;

    double parameter = 0.0;
    if (operation == op_derivative) {
        if (cursor != length) return -1;
    } else if (operation == op_evaluate || operation == op_integral) {
        if (cursor + 1 != length) return -1;
        parameter = values[cursor];
        const double minimum = operation == op_evaluate ? -2.0 : -10.0;
        const double maximum = operation == op_evaluate ? 2.0 : 10.0;
        if (parameter < minimum || parameter > maximum) return -1;
    } else if (cursor != length) {
        return -1;
    }

    double result[max_output_elements]{};
    std::size_t result_count = 0;
    if (operation == op_add) {
        add_polynomials(degree_a, coefficients_a, degree_b, coefficients_b, result, result_count);
    } else if (operation == op_subtract) {
        double negated[max_coefficients]{};
        for (int index = 0; index <= degree_b; ++index) {
            const double product = rounded_multiply(coefficients_b[index], -1.0);
            negated[index] = rounded_add(negated[index], product);
        }
        add_polynomials(degree_a, coefficients_a, degree_b, negated, result, result_count);
    } else if (operation == op_multiply) {
        multiply_polynomials(degree_a, coefficients_a, degree_b, coefficients_b,
                             result, result_count);
    } else if (operation == op_evaluate) {
        double accumulated = 0.0;
        for (int index = 0; index <= degree_a; ++index) {
            const double power = std::pow(parameter, static_cast<double>(index));
            const double term = rounded_multiply(coefficients_a[index], power);
            accumulated = rounded_add(accumulated, term);
        }
        result[0] = accumulated;
        result_count = 1;
    } else if (operation == op_derivative) {
        for (int index = 0; index < degree_a; ++index)
            result[index] = rounded_multiply(coefficients_a[index + 1],
                                             static_cast<double>(index + 1));
        result_count = static_cast<std::size_t>(degree_a);
    } else {
        result[0] = parameter;
        for (int index = 0; index <= degree_a; ++index)
            result[index + 1] = rounded_divide(coefficients_a[index],
                                               static_cast<double>(index + 1));
        result_count = static_cast<std::size_t>(degree_a + 2);
    }

    if (result_count > max_output_elements) return -1;
    for (std::size_t index = 0; index < result_count; ++index)
        if (!finite_value(result[index])) return -1;

    if (output == nullptr || output_capacity < result_count) return -2;
    for (std::size_t index = 0; index < result_count; ++index) output[index] = result[index];
    return static_cast<std::int64_t>(result_count);
}
