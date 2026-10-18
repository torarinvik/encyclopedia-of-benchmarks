/* QR factorization property diagnostics for bounded square matrices. */
#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 4
#define MAX_PARSEABLE_INPUT_LENGTH 18
#define OUTPUT_ELEMENTS 3

static double rounded_add(double left, double right)
{
    volatile double result = left + right;
    return result;
}

static double rounded_subtract(double left, double right)
{
    volatile double result = left - right;
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

static int exact_integer_in_range(double value, int64_t minimum, int64_t maximum,
                                  int64_t *integer)
{
    if (!isfinite(value) || value < (double)minimum || value > (double)maximum) return 0;
    const int64_t converted = (int64_t)value;
    if ((double)converted != value) return 0;
    *integer = converted;
    return 1;
}

static int64_t exact_determinant(const int64_t *source, size_t dimension)
{
    int64_t matrix[MAX_DIMENSION * MAX_DIMENSION] = {0};
    for (size_t index = 0; index < dimension * dimension; ++index) matrix[index] = source[index];

    int64_t sign = 1;
    int64_t previous_pivot = 1;
    for (size_t col = 0; col + 1 < dimension; ++col) {
        size_t pivot_row = col;
        while (pivot_row < dimension && matrix[pivot_row * dimension + col] == 0) ++pivot_row;
        if (pivot_row == dimension) return 0;

        if (pivot_row != col) {
            for (size_t index = 0; index < dimension; ++index) {
                const int64_t temporary = matrix[col * dimension + index];
                matrix[col * dimension + index] = matrix[pivot_row * dimension + index];
                matrix[pivot_row * dimension + index] = temporary;
            }
            sign = -sign;
        }

        const int64_t pivot = matrix[col * dimension + col];
        for (size_t row = col + 1; row < dimension; ++row) {
            for (size_t trailing_col = col + 1; trailing_col < dimension; ++trailing_col) {
                int64_t numerator = matrix[row * dimension + trailing_col] * pivot -
                                    matrix[row * dimension + col] * matrix[col * dimension + trailing_col];
                if (col > 0) numerator /= previous_pivot;
                matrix[row * dimension + trailing_col] = numerator;
            }
            matrix[row * dimension + col] = 0;
        }
        previous_pivot = pivot;
    }

    return sign * matrix[(dimension - 1) * dimension + dimension - 1];
}

static int leading_principal_minors_are_nonzero(const int64_t *matrix, size_t dimension)
{
    for (size_t order = 1; order <= dimension; ++order) {
        int64_t leading[MAX_DIMENSION * MAX_DIMENSION] = {0};
        for (size_t row = 0; row < order; ++row)
            for (size_t col = 0; col < order; ++col)
                leading[row * order + col] = matrix[row * dimension + col];
        if (exact_determinant(leading, order) == 0) return 0;
    }
    return 1;
}

static double dot_product(const double *left, const double *right, size_t length)
{
    double total = 0.0;
    for (size_t index = 0; index < length; ++index)
        total = rounded_add(total, rounded_multiply(left[index], right[index]));
    return total;
}

int64_t qr_decomposition(const double *input, size_t input_length,
                         double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    int64_t dimension_value;
    if (!exact_integer_in_range(input[0], 1, MAX_DIMENSION, &dimension_value)) return -1;
    const size_t dimension = (size_t)dimension_value;
    const size_t matrix_elements = dimension * dimension;
    if (input_length != 1 + matrix_elements) return -1;

    int64_t integer_matrix[MAX_DIMENSION * MAX_DIMENSION] = {0};
    double matrix[MAX_DIMENSION * MAX_DIMENSION] = {0.0};
    for (size_t index = 0; index < matrix_elements; ++index) {
        int64_t integer;
        if (!exact_integer_in_range(input[index + 1], -1, 1, &integer)) return -1;
        integer_matrix[index] = integer;
        matrix[index] = (double)integer;
    }
    if (!leading_principal_minors_are_nonzero(integer_matrix, dimension)) return -1;

    double q[MAX_DIMENSION * MAX_DIMENSION] = {0.0};
    double r[MAX_DIMENSION * MAX_DIMENSION] = {0.0};
    double source_column[MAX_DIMENSION] = {0.0};
    double residual[MAX_DIMENSION] = {0.0};
    double basis[MAX_DIMENSION] = {0.0};
    double a_column[MAX_DIMENSION] = {0.0};

    for (size_t col = 0; col < dimension; ++col) {
        for (size_t row = 0; row < dimension; ++row) {
            source_column[row] = matrix[row * dimension + col];
            residual[row] = source_column[row];
        }

        for (size_t previous = 0; previous < col; ++previous) {
            for (size_t row = 0; row < dimension; ++row)
                basis[row] = q[row * dimension + previous];

            const double numerator = dot_product(source_column, basis, dimension);
            const double denominator = dot_product(basis, basis, dimension);
            if (!isfinite(numerator) || !isfinite(denominator) || denominator <= 0.0) return -1;
            const double scalar = rounded_divide(numerator, denominator);
            if (!isfinite(scalar)) return -1;
            for (size_t row = 0; row < dimension; ++row) {
                const double projection = rounded_multiply(scalar, basis[row]);
                residual[row] = rounded_subtract(residual[row], projection);
                if (!isfinite(residual[row])) return -1;
            }
        }

        const double residual_squared = dot_product(residual, residual, dimension);
        const double magnitude = sqrt(residual_squared);
        if (!isfinite(residual_squared) || !isfinite(magnitude) || magnitude <= 0.0) return -1;
        for (size_t row = 0; row < dimension; ++row) {
            q[row * dimension + col] = rounded_divide(residual[row], magnitude);
            if (!isfinite(q[row * dimension + col])) return -1;
        }

        for (size_t row = 0; row <= col; ++row) {
            for (size_t index = 0; index < dimension; ++index)
                basis[index] = q[index * dimension + row];
            for (size_t index = 0; index < dimension; ++index)
                a_column[index] = matrix[index * dimension + col];
            r[row * dimension + col] = dot_product(basis, a_column, dimension);
            if (!isfinite(r[row * dimension + col])) return -1;
        }
    }

    double reconstruction_squared = 0.0;
    double orthogonality_squared = 0.0;
    double lower_triangle_squared = 0.0;
    for (size_t row = 0; row < dimension; ++row) {
        for (size_t col = 0; col < dimension; ++col) {
            double reconstructed = 0.0;
            double orthogonality = 0.0;
            for (size_t index = 0; index < dimension; ++index) {
                reconstructed = rounded_add(reconstructed,
                    rounded_multiply(q[row * dimension + index], r[index * dimension + col]));
                orthogonality = rounded_add(orthogonality,
                    rounded_multiply(q[index * dimension + row], q[index * dimension + col]));
            }
            const double reconstruction_error = rounded_subtract(matrix[row * dimension + col], reconstructed);
            if (row == col) orthogonality = rounded_subtract(orthogonality, 1.0);
            if (!isfinite(reconstruction_error) || !isfinite(orthogonality)) return -1;
            reconstruction_squared = rounded_add(reconstruction_squared,
                rounded_multiply(reconstruction_error, reconstruction_error));
            orthogonality_squared = rounded_add(orthogonality_squared,
                rounded_multiply(orthogonality, orthogonality));
            if (row > col)
                lower_triangle_squared = rounded_add(lower_triangle_squared,
                    rounded_multiply(r[row * dimension + col], r[row * dimension + col]));
        }
    }

    const double staged[OUTPUT_ELEMENTS] = {
        sqrt(reconstruction_squared), sqrt(orthogonality_squared), sqrt(lower_triangle_squared)
    };
    for (size_t index = 0; index < OUTPUT_ELEMENTS; ++index)
        if (!isfinite(staged[index])) return -1;

    if (output == NULL || output_capacity < OUTPUT_ELEMENTS) return -2;
    for (size_t index = 0; index < OUTPUT_ELEMENTS; ++index) output[index] = staged[index];
    return OUTPUT_ELEMENTS;
}
