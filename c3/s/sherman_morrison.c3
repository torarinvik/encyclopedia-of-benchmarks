module sherman_morrison;

const usz MIN_DIMENSION = 1;
const usz MAX_DIMENSION = 4;
const usz MAX_PARSEABLE_INPUT_LENGTH = 26;
const usz MAX_OUTPUT_ELEMENTS = 16;
const double MAX_FINITE = 1.7976931348623157e308;

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

fn bool finite_value(double value) {
    return value == value && value <= MAX_FINITE && value >= -MAX_FINITE;
}

fn bool exact_integer_in_range(double value, long minimum, long maximum) {
    if (!finite_value(value) || value < (double)minimum || value > (double)maximum) return false;
    return value == (double)(long)value;
}

fn long sherman_morrison(double* input, usz input_length,
                         double* output, usz output_capacity)
    @export("sherman_morrison")
{
    if (input == null || input_length == 0 ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (usz i = 0; i < input_length; i++) {
        if (!finite_value(input[i])) return -1;
    }

    if (!exact_integer_in_range(input[0], (long)MIN_DIMENSION,
                                (long)MAX_DIMENSION)) return -1;
    usz dimension = (usz)input[0];
    usz matrix_size = dimension * dimension;
    usz expected_length = 1 + matrix_size + 2 * dimension;
    if (input_length != expected_length) return -1;

    for (usz i = 1; i < input_length; i++) {
        if (!exact_integer_in_range(input[i], -2, 2)) return -1;
    }

    double[MAX_OUTPUT_ELEMENTS] inverse = zeroed;
    double[MAX_DIMENSION] u = zeroed;
    double[MAX_DIMENSION] v = zeroed;
    for (usz i = 0; i < matrix_size; i++) inverse[i] = input[1 + i];
    for (usz i = 0; i < dimension; i++) {
        u[i] = input[1 + matrix_size + i];
        v[i] = input[1 + matrix_size + dimension + i];
    }

    // Preserve the source's left-associated (v^T * A_inverse) * u order.
    double[MAX_DIMENSION] right_vector = zeroed;
    for (usz column = 0; column < dimension; column++) {
        double sum = 0.0;
        for (usz inner = 0; inner < dimension; inner++) {
            sum = rounded_add(sum,
                              rounded_multiply(v[inner], inverse[inner * dimension + column]));
        }
        right_vector[column] = sum;
    }

    double denominator_term = 0.0;
    for (usz inner = 0; inner < dimension; inner++) {
        denominator_term = rounded_add(denominator_term,
                                       rounded_multiply(right_vector[inner], u[inner]));
    }
    double denominator = rounded_add(1.0, denominator_term);
    bool singular = denominator == 0.0;

    double[MAX_OUTPUT_ELEMENTS] results = zeroed;
    if (!singular) {
        double[MAX_DIMENSION] left_vector = zeroed;
        for (usz row = 0; row < dimension; row++) {
            double sum = 0.0;
            for (usz inner = 0; inner < dimension; inner++) {
                sum = rounded_add(sum,
                                  rounded_multiply(inverse[row * dimension + inner], u[inner]));
            }
            left_vector[row] = sum;
        }

        double reciprocal = rounded_divide(1.0, denominator);
        for (usz row = 0; row < dimension; row++) {
            for (usz column = 0; column < dimension; column++) {
                double outer_product = rounded_multiply(left_vector[row], right_vector[column]);
                double correction = rounded_multiply(outer_product, reciprocal);
                results[row * dimension + column] =
                    rounded_subtract(inverse[row * dimension + column], correction);
            }
        }
    }

    // Null output is an ABI error even when the source result is None.
    if (output == null) return -2;
    if (singular) return 0;

    usz output_length = matrix_size;
    if (output_capacity < output_length) return -2;
    for (usz i = 0; i < output_length; i++) output[i] = results[i];
    return (long)output_length;
}
