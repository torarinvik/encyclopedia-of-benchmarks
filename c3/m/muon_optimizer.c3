module muon_optimizer;

const MAX_GROUP_COUNT = 4;
const MAX_ROWS = 4;
const MAX_COLUMNS = 4;
const MAX_MATRIX_ELEMENTS = 16;
const MAX_GROUP_MATRIX_ELEMENTS = 32;
const MAX_CALL_COUNT = 8;
const MAX_VALID_INPUT_LENGTH = 271;
const MAX_PARSEABLE_INPUT_LENGTH = 272;

fn bool finite_value(double value) {
    return value == value && value >= -1.7976931348623157e308 &&
           value <= 1.7976931348623157e308;
}

fn bool exact_bounded_integer(double value, usz minimum, usz maximum, usz* result) {
    if (!finite_value(value) || value < (double)minimum || value > (double)maximum) return false;
    usz converted = (usz)(long)value;
    if (value != (double)converted) return false;
    *result = converted;
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

fn void orthogonalize(double* gradient, usz rows, usz columns, usz ns_steps, double* result) {
    bool transposed = rows < columns;
    usz working_rows = transposed ? columns : rows;
    usz working_columns = transposed ? rows : columns;
    double matrix[4][4] = {{0}};

    for (usz row = 0; row < rows; row++) {
        for (usz column = 0; column < columns; column++) {
            if (transposed) matrix[column][row] = gradient[row * columns + column];
            else matrix[row][column] = gradient[row * columns + column];
        }
    }

    for (usz step = 0; step < ns_steps; step++) {
        double gram[4][4] = {{0}};
        double product[4][4] = {{0}};
        for (usz left = 0; left < working_columns; left++) {
            for (usz right = 0; right < working_columns; right++) {
                double sum = 0.0;
                for (usz row = 0; row < working_rows; row++)
                    sum = rounded_add(sum, rounded_multiply(matrix[row][left], matrix[row][right]));
                gram[left][right] = sum;
            }
        }
        for (usz row = 0; row < working_rows; row++) {
            for (usz column = 0; column < working_columns; column++) {
                double sum = 0.0;
                for (usz inner = 0; inner < working_columns; inner++)
                    sum = rounded_add(sum, rounded_multiply(matrix[row][inner], gram[inner][column]));
                product[row][column] = sum;
            }
        }
        for (usz row = 0; row < working_rows; row++) {
            for (usz column = 0; column < working_columns; column++)
                matrix[row][column] = rounded_subtract(
                    rounded_multiply(1.5, matrix[row][column]),
                    rounded_multiply(0.5, product[row][column]));
        }
    }

    for (usz row = 0; row < rows; row++) {
        for (usz column = 0; column < columns; column++)
            result[row * columns + column] = transposed ? matrix[column][row] : matrix[row][column];
    }
}

fn long muon_optimizer(double* input, usz input_length, double* output, usz output_capacity)
    @export("muon_optimizer")
{
    if (input == null || input_length < 10 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (usz index = 0; index < input_length; index++)
        if (!finite_value(input[index])) return -1;

    usz group_count, rows, columns, call_count, ns_steps;
    if (!exact_bounded_integer(input[0], 1, MAX_GROUP_COUNT, &group_count) ||
        !exact_bounded_integer(input[1], 1, MAX_ROWS, &rows) ||
        !exact_bounded_integer(input[2], 1, MAX_COLUMNS, &columns) ||
        !exact_bounded_integer(input[3], 1, MAX_CALL_COUNT, &call_count) ||
        !exact_bounded_integer(input[4], 0, 5, &ns_steps)) return -1;

    usz matrix_elements = rows * columns;
    if (matrix_elements > MAX_MATRIX_ELEMENTS ||
        group_count * matrix_elements > MAX_GROUP_MATRIX_ELEMENTS ||
        call_count < group_count) return -1;
    usz expected_length = 7 + call_count * (1 + 2 * matrix_elements);
    if (input_length != expected_length || input_length > MAX_VALID_INPUT_LENGTH) return -1;

    double learning_rate = input[5];
    double momentum = input[6];
    if (learning_rate < 0.0 || learning_rate > 0.25 ||
        momentum < 0.0 || momentum > 0.99) return -1;

    usz[MAX_CALL_COUNT] ids = {0};
    double[MAX_CALL_COUNT * MAX_MATRIX_ELEMENTS] event_params = {0.0};
    double[MAX_CALL_COUNT * MAX_MATRIX_ELEMENTS] event_gradients = {0.0};
    bool[MAX_GROUP_COUNT] seen = {false};
    usz cursor = 7;
    for (usz event = 0; event < call_count; event++) {
        usz id;
        if (!exact_bounded_integer(input[cursor], 0, group_count - 1, &id)) return -1;
        ids[event] = id;
        seen[id] = true;
        cursor++;
        for (usz element = 0; element < matrix_elements; element++) {
            double value = input[cursor + element];
            if (value < -10.0 || value > 10.0) return -1;
            event_params[event * matrix_elements + element] = value;
        }
        cursor += matrix_elements;
        for (usz element = 0; element < matrix_elements; element++) {
            double value = input[cursor + element];
            if (value < -0.01 || value > 0.01) return -1;
            event_gradients[event * matrix_elements + element] = value;
        }
        cursor += matrix_elements;
    }
    for (usz id = 0; id < group_count; id++)
        if (!seen[id]) return -1;

    usz group_elements = group_count * matrix_elements;
    usz output_elements = 2 * group_elements;
    if (output == null || output_capacity < output_elements) return -2;

    double[MAX_GROUP_MATRIX_ELEMENTS] velocities = {0.0};
    double[MAX_GROUP_MATRIX_ELEMENTS] last_params = {0.0};
    for (usz event = 0; event < call_count; event++) {
        usz id = ids[event];
        usz state_offset = id * matrix_elements;
        double[MAX_MATRIX_ELEMENTS] orthogonalized = {0.0};
        orthogonalize(&event_gradients[event * matrix_elements], rows, columns,
                      ns_steps, &orthogonalized[0]);
        for (usz element = 0; element < matrix_elements; element++) {
            usz state_index = state_offset + element;
            usz event_index = event * matrix_elements + element;
            velocities[state_index] = rounded_add(
                rounded_multiply(momentum, velocities[state_index]), orthogonalized[element]);
            last_params[state_index] = rounded_subtract(
                event_params[event_index],
                rounded_multiply(learning_rate, velocities[state_index]));
        }
    }
    for (usz index = 0; index < group_elements; index++) {
        output[index] = last_params[index];
        output[group_elements + index] = velocities[index];
    }
    return (long)output_elements;
}
