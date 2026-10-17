module lu_pivot_decomposition;

const usz MAX_DIMENSION = 4;
const usz MAX_PARSEABLE_INPUT_LENGTH = 18;
const usz MAX_OUTPUT_ELEMENTS = 21;

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

fn double rounded_subtract(double left, double right) @noinline {
    return left - right;
}

fn double rounded_divide(double left, double right) @noinline {
    return left / right;
}

fn long lu_pivot_decomposition(double* input, usz input_length, double* output, usz output_capacity)
    @export("lu_pivot_decomposition") {
    if (input == null || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;

    long dimension_value;
    if (!exact_integer_in_range(input[0], 1, (long)MAX_DIMENSION, &dimension_value)) return -1L;
    usz dimension = (usz)dimension_value;
    usz matrix_elements = dimension * dimension;
    if (input_length != 1 + matrix_elements) return -1L;

    double[MAX_DIMENSION * MAX_DIMENSION] packed_lu = zeroed;
    for (usz index = 0; index < matrix_elements; index++) {
        long integer;
        if (!exact_integer_in_range(input[index + 1], -8, 8, &integer)) return -1L;
        packed_lu[index] = (double)integer;
    }

    long[MAX_DIMENSION + 1] pivot = zeroed;
    for (usz index = 0; index <= dimension; index++) pivot[index] = (long)index;

    for (usz col = 0; col < dimension; col++) {
        double max_value = 0.0;
        usz max_index = col;
        for (usz row = col; row < dimension; row++) {
            double entry = packed_lu[row * dimension + col];
            double magnitude = entry < 0.0 ? -entry : entry;
            if (magnitude > max_value) {
                max_value = magnitude;
                max_index = row;
            }
        }

        if (max_index != col) {
            for (usz index = 0; index < dimension; index++) {
                double temporary = packed_lu[col * dimension + index];
                packed_lu[col * dimension + index] = packed_lu[max_index * dimension + index];
                packed_lu[max_index * dimension + index] = temporary;
            }
            long temporary = pivot[col];
            pivot[col] = pivot[max_index];
            pivot[max_index] = temporary;
            pivot[dimension]++;
        }

        double pivot_value = packed_lu[col * dimension + col];
        if (!finite_value(pivot_value) || pivot_value == 0.0) return -1L;

        for (usz row = col + 1; row < dimension; row++) {
            double multiplier = rounded_divide(packed_lu[row * dimension + col], pivot_value);
            if (!finite_value(multiplier)) return -1L;
            packed_lu[row * dimension + col] = multiplier;

            for (usz trailing_col = col + 1; trailing_col < dimension; trailing_col++) {
                double product = rounded_multiply(multiplier,
                                                  packed_lu[col * dimension + trailing_col]);
                double value = rounded_subtract(packed_lu[row * dimension + trailing_col], product);
                if (!finite_value(value)) return -1L;
                packed_lu[row * dimension + trailing_col] = value;
            }
        }
    }

    double[MAX_OUTPUT_ELEMENTS] staged = zeroed;
    for (usz index = 0; index < matrix_elements; index++) {
        if (!finite_value(packed_lu[index])) return -1L;
        staged[index] = packed_lu[index];
    }
    usz output_length = matrix_elements + dimension + 1;
    for (usz index = 0; index <= dimension; index++)
        staged[matrix_elements + index] = (double)pivot[index];

    if (output == null || output_capacity < output_length) return -2L;
    for (usz index = 0; index < output_length; index++) output[index] = staged[index];
    return (long)output_length;
}
