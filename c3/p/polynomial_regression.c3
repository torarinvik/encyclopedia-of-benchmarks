module polynomial_regression;

extern fn double sqrt(double value);

const usz MAX_INPUT_LENGTH = 18;
const usz MAX_TRAINING_COUNT = 5;
const usz MAX_COLUMNS = 4;
const usz MAX_OUTPUT_ELEMENTS = 8;
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

fn long polynomial_regression(double* input, usz input_length, double* output, usz output_capacity)
    @export("polynomial_regression")
{
    if (input == null || input_length < 3 || input_length > MAX_INPUT_LENGTH) return -1;
    for (usz i = 0; i < input_length; i++) {
        if (!finite_value(input[i])) return -1;
    }

    if (!exact_integer_in_range(input[0], 0, 3) ||
        !exact_integer_in_range(input[1], 1, (long)MAX_TRAINING_COUNT) ||
        !exact_integer_in_range(input[2], 1, 4)) return -1;

    usz degree = (usz)input[0];
    usz training_count = (usz)input[1];
    usz query_count = (usz)input[2];
    usz columns = degree + 1;
    if (training_count < columns) return -1;
    usz expected_length = 3 + 2 * training_count + query_count;
    if (input_length != expected_length) return -1;

    double[MAX_TRAINING_COUNT] x_train = zeroed;
    double[MAX_TRAINING_COUNT] y_train = zeroed;
    double[4] x_query = zeroed;
    for (usz row = 0; row < training_count; row++) {
        double x = input[3 + row];
        double y = input[3 + training_count + row];
        if (!exact_integer_in_range(x, -2, 2) || !exact_integer_in_range(y, -32, 32)) return -1;
        x_train[row] = x;
        y_train[row] = y;
    }
    for (usz query = 0; query < query_count; query++) {
        double x = input[3 + 2 * training_count + query];
        if (!exact_integer_in_range(x, -2, 2)) return -1;
        x_query[query] = x;
    }
    for (usz row = 0; row < training_count; row++) {
        for (usz previous = 0; previous < row; previous++) {
            if (x_train[row] == x_train[previous]) return -1;
        }
    }

    double[MAX_TRAINING_COUNT * MAX_COLUMNS] design = zeroed;
    for (usz row = 0; row < training_count; row++) {
        double power = 1.0;
        for (usz column = 0; column < columns; column++) {
            design[row * columns + column] = power;
            power = rounded_multiply(power, x_train[row]);
        }
    }

    double[MAX_TRAINING_COUNT * MAX_COLUMNS] q_matrix = zeroed;
    double[MAX_COLUMNS * MAX_COLUMNS] r_matrix = zeroed;
    for (usz column = 0; column < columns; column++) {
        double[MAX_TRAINING_COUNT] vector = zeroed;
        for (usz row = 0; row < training_count; row++) {
            vector[row] = design[row * columns + column];
        }
        for (usz previous = 0; previous < column; previous++) {
            double dot = 0.0;
            for (usz row = 0; row < training_count; row++) {
                dot = rounded_add(dot, rounded_multiply(q_matrix[row * columns + previous],
                                                        vector[row]));
            }
            r_matrix[previous * columns + column] = dot;
            for (usz row = 0; row < training_count; row++) {
                double projection = rounded_multiply(dot, q_matrix[row * columns + previous]);
                vector[row] = rounded_subtract(vector[row], projection);
            }
        }

        double norm_squared = 0.0;
        for (usz row = 0; row < training_count; row++) {
            norm_squared = rounded_add(norm_squared, rounded_multiply(vector[row], vector[row]));
        }
        if (!finite_value(norm_squared) || norm_squared <= 0.0) return -1;
        double norm = sqrt(norm_squared);
        if (!finite_value(norm) || norm <= 0.0) return -1;
        r_matrix[column * columns + column] = norm;
        for (usz row = 0; row < training_count; row++) {
            q_matrix[row * columns + column] = rounded_divide(vector[row], norm);
        }
    }

    double[MAX_COLUMNS] projected = zeroed;
    for (usz column = 0; column < columns; column++) {
        for (usz row = 0; row < training_count; row++) {
            projected[column] = rounded_add(projected[column],
                                            rounded_multiply(q_matrix[row * columns + column],
                                                             y_train[row]));
        }
    }

    double[MAX_COLUMNS] coefficients = zeroed;
    usz remaining = columns;
    while (remaining > 0) {
        usz column = remaining - 1;
        double value = projected[column];
        for (usz next = column + 1; next < columns; next++) {
            value = rounded_subtract(value,
                                    rounded_multiply(r_matrix[column * columns + next],
                                                     coefficients[next]));
        }
        double diagonal = r_matrix[column * columns + column];
        if (!finite_value(diagonal) || diagonal == 0.0) return -1;
        coefficients[column] = rounded_divide(value, diagonal);
        if (!finite_value(coefficients[column])) return -1;
        remaining--;
    }

    double[MAX_OUTPUT_ELEMENTS] results = zeroed;
    for (usz column = 0; column < columns; column++) results[column] = coefficients[column];
    for (usz query = 0; query < query_count; query++) {
        double prediction = 0.0;
        double power = 1.0;
        for (usz column = 0; column < columns; column++) {
            prediction = rounded_add(prediction, rounded_multiply(power, coefficients[column]));
            power = rounded_multiply(power, x_query[query]);
        }
        if (!finite_value(prediction)) return -1;
        results[columns + query] = prediction;
    }

    usz output_length = columns + query_count;
    if (output == null || output_capacity < output_length) return -2;
    for (usz i = 0; i < output_length; i++) output[i] = results[i];
    return (long)output_length;
}
