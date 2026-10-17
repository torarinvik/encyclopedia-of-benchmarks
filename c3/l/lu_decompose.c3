module lu_decompose;

const usz MAX_DIMENSION = 4;
const usz MAX_PARSEABLE_INPUT_LENGTH = 18;
const usz MAX_OUTPUT_ELEMENTS = 32;

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

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn double rounded_add(double left, double right) @noinline {
    return left + right;
}

fn double rounded_subtract(double left, double right) @noinline {
    return left - right;
}

fn double rounded_divide(double left, double right) @noinline {
    return left / right;
}

fn long lu_decompose(double* input, usz input_length, double* output, usz output_capacity)
    @export("lu_decompose") {
    if (input == null || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;

    long dimension_value;
    if (!exact_integer_in_range(input[0], 1, (long)MAX_DIMENSION, &dimension_value)) return -1L;
    usz dimension = (usz)dimension_value;
    usz matrix_elements = dimension * dimension;
    usz expected_length = 1 + matrix_elements;
    if (input_length != expected_length) return -1L;

    double[MAX_DIMENSION * MAX_DIMENSION] matrix = zeroed;
    for (usz index = 0; index < matrix_elements; index++) {
        long integer;
        if (!exact_integer_in_range(input[index + 1], -8, 8, &integer)) return -1L;
        matrix[index] = (double)integer;
    }

    double[MAX_DIMENSION * MAX_DIMENSION] lower = zeroed;
    double[MAX_DIMENSION * MAX_DIMENSION] upper = zeroed;
    for (usz row = 0; row < dimension; row++) {
        for (usz col = row; col < dimension; col++) {
            double lu_sum = 0.0;
            for (usz index = 0; index < row; index++) {
                double product = rounded_multiply(lower[row * dimension + index],
                                                  upper[index * dimension + col]);
                lu_sum = rounded_add(lu_sum, product);
            }
            upper[row * dimension + col] = rounded_subtract(matrix[row * dimension + col], lu_sum);
            if (!finite_value(upper[row * dimension + col])) return -1L;
        }

        double pivot = upper[row * dimension + row];
        if (!finite_value(pivot) || pivot == 0.0) return -1L;
        for (usz col = row; col < dimension; col++) {
            if (row == col) {
                lower[row * dimension + col] = 1.0;
                continue;
            }
            double lu_sum = 0.0;
            for (usz index = 0; index < row; index++) {
                double product = rounded_multiply(lower[col * dimension + index],
                                                  upper[index * dimension + row]);
                lu_sum = rounded_add(lu_sum, product);
            }
            double numerator = rounded_subtract(matrix[col * dimension + row], lu_sum);
            double value = rounded_divide(numerator, pivot);
            if (!finite_value(value)) return -1L;
            lower[col * dimension + row] = value;
        }
    }

    double[MAX_OUTPUT_ELEMENTS] staged = zeroed;
    for (usz index = 0; index < matrix_elements; index++) {
        if (!finite_value(lower[index]) || !finite_value(upper[index])) return -1L;
        staged[index] = lower[index];
        staged[matrix_elements + index] = upper[index];
    }

    usz output_length = 2 * matrix_elements;
    if (output == null || output_capacity < output_length) return -2L;
    for (usz index = 0; index < output_length; index++) output[index] = staged[index];
    return (long)output_length;
}
