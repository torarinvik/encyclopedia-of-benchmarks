module qr_decomposition;

extern fn double sqrt(double value);

const usz MAX_DIMENSION = 4;
const usz MAX_PARSEABLE_INPUT_LENGTH = 18;
const usz OUTPUT_ELEMENTS = 3;

fn bool finite_value(double value) {
    return value == value && value >= -1e308 && value <= 1e308;
}

fn bool exact_integer_in_range(double value, long minimum, long maximum, long* integer) {
    if (!finite_value(value) || value < (double)minimum || value > (double)maximum) return false;
    long converted = (long)value;
    if ((double)converted != value) return false;
    *integer = converted;
    return true;
}

fn double rounded_add(double left, double right) @noinline {
    return left + right;
}

fn double rounded_subtract(double left, double right) @noinline {
    return left - right;
}

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn double rounded_divide(double left, double right) @noinline {
    return left / right;
}

fn long exact_determinant(long* source, usz dimension) {
    long[MAX_DIMENSION * MAX_DIMENSION] matrix = zeroed;
    for (usz index = 0; index < dimension * dimension; index++) matrix[index] = source[index];

    long sign = 1;
    long previous_pivot = 1;
    for (usz col = 0; col + 1 < dimension; col++) {
        usz pivot_row = col;
        while (pivot_row < dimension && matrix[pivot_row * dimension + col] == 0) pivot_row++;
        if (pivot_row == dimension) return 0;

        if (pivot_row != col) {
            for (usz index = 0; index < dimension; index++) {
                long temporary = matrix[col * dimension + index];
                matrix[col * dimension + index] = matrix[pivot_row * dimension + index];
                matrix[pivot_row * dimension + index] = temporary;
            }
            sign = -sign;
        }

        long pivot = matrix[col * dimension + col];
        for (usz row = col + 1; row < dimension; row++) {
            for (usz trailing_col = col + 1; trailing_col < dimension; trailing_col++) {
                long numerator = matrix[row * dimension + trailing_col] * pivot -
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

fn bool leading_principal_minors_are_nonzero(long* matrix, usz dimension) {
    for (usz order = 1; order <= dimension; order++) {
        long[MAX_DIMENSION * MAX_DIMENSION] leading = zeroed;
        for (usz row = 0; row < order; row++)
            for (usz col = 0; col < order; col++)
                leading[row * order + col] = matrix[row * dimension + col];
        if (exact_determinant(leading, order) == 0) return false;
    }
    return true;
}

fn double dot_product(double* left, double* right, usz length) {
    double total = 0.0;
    for (usz index = 0; index < length; index++)
        total = rounded_add(total, rounded_multiply(left[index], right[index]));
    return total;
}

fn long qr_decomposition(double* input, usz input_length, double* output, usz output_capacity)
    @export("qr_decomposition") {
    if (input == null || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;

    long dimension_value;
    if (!exact_integer_in_range(input[0], 1, (long)MAX_DIMENSION, &dimension_value)) return -1L;
    usz dimension = (usz)dimension_value;
    usz matrix_elements = dimension * dimension;
    if (input_length != 1 + matrix_elements) return -1L;

    long[MAX_DIMENSION * MAX_DIMENSION] integer_matrix = zeroed;
    double[MAX_DIMENSION * MAX_DIMENSION] matrix = zeroed;
    for (usz index = 0; index < matrix_elements; index++) {
        long integer;
        if (!exact_integer_in_range(input[index + 1], -1, 1, &integer)) return -1L;
        integer_matrix[index] = integer;
        matrix[index] = (double)integer;
    }
    if (!leading_principal_minors_are_nonzero(integer_matrix, dimension)) return -1L;

    double[MAX_DIMENSION * MAX_DIMENSION] q = zeroed;
    double[MAX_DIMENSION * MAX_DIMENSION] r = zeroed;
    double[MAX_DIMENSION] source_column = zeroed;
    double[MAX_DIMENSION] residual = zeroed;
    double[MAX_DIMENSION] basis = zeroed;
    double[MAX_DIMENSION] a_column = zeroed;

    for (usz col = 0; col < dimension; col++) {
        for (usz row = 0; row < dimension; row++) {
            source_column[row] = matrix[row * dimension + col];
            residual[row] = source_column[row];
        }

        for (usz previous = 0; previous < col; previous++) {
            for (usz row = 0; row < dimension; row++) basis[row] = q[row * dimension + previous];

            double numerator = dot_product(source_column, basis, dimension);
            double denominator = dot_product(basis, basis, dimension);
            if (!finite_value(numerator) || !finite_value(denominator) || denominator <= 0.0) return -1L;
            double scalar = rounded_divide(numerator, denominator);
            if (!finite_value(scalar)) return -1L;
            for (usz row = 0; row < dimension; row++) {
                double projection = rounded_multiply(scalar, basis[row]);
                residual[row] = rounded_subtract(residual[row], projection);
                if (!finite_value(residual[row])) return -1L;
            }
        }

        double residual_squared = dot_product(residual, residual, dimension);
        double magnitude = sqrt(residual_squared);
        if (!finite_value(residual_squared) || !finite_value(magnitude) || magnitude <= 0.0) return -1L;
        for (usz row = 0; row < dimension; row++) {
            q[row * dimension + col] = rounded_divide(residual[row], magnitude);
            if (!finite_value(q[row * dimension + col])) return -1L;
        }

        for (usz row = 0; row <= col; row++) {
            for (usz index = 0; index < dimension; index++) basis[index] = q[index * dimension + row];
            for (usz index = 0; index < dimension; index++) a_column[index] = matrix[index * dimension + col];
            r[row * dimension + col] = dot_product(basis, a_column, dimension);
            if (!finite_value(r[row * dimension + col])) return -1L;
        }
    }

    double reconstruction_squared = 0.0;
    double orthogonality_squared = 0.0;
    double lower_triangle_squared = 0.0;
    for (usz row = 0; row < dimension; row++) {
        for (usz col = 0; col < dimension; col++) {
            double reconstructed = 0.0;
            double orthogonality = 0.0;
            for (usz index = 0; index < dimension; index++) {
                reconstructed = rounded_add(reconstructed,
                    rounded_multiply(q[row * dimension + index], r[index * dimension + col]));
                orthogonality = rounded_add(orthogonality,
                    rounded_multiply(q[index * dimension + row], q[index * dimension + col]));
            }
            double reconstruction_error = rounded_subtract(matrix[row * dimension + col], reconstructed);
            if (row == col) orthogonality = rounded_subtract(orthogonality, 1.0);
            if (!finite_value(reconstruction_error) || !finite_value(orthogonality)) return -1L;
            reconstruction_squared = rounded_add(reconstruction_squared,
                rounded_multiply(reconstruction_error, reconstruction_error));
            orthogonality_squared = rounded_add(orthogonality_squared,
                rounded_multiply(orthogonality, orthogonality));
            if (row > col)
                lower_triangle_squared = rounded_add(lower_triangle_squared,
                    rounded_multiply(r[row * dimension + col], r[row * dimension + col]));
        }
    }

    double[OUTPUT_ELEMENTS] staged = zeroed;
    staged[0] = sqrt(reconstruction_squared);
    staged[1] = sqrt(orthogonality_squared);
    staged[2] = sqrt(lower_triangle_squared);
    for (usz index = 0; index < OUTPUT_ELEMENTS; index++)
        if (!finite_value(staged[index])) return -1L;

    if (output == null || output_capacity < OUTPUT_ELEMENTS) return -2L;
    for (usz index = 0; index < OUTPUT_ELEMENTS; index++) output[index] = staged[index];
    return (long)OUTPUT_ELEMENTS;
}
