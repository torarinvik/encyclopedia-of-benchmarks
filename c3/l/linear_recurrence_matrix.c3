module linear_recurrence_matrix;

const long MODULUS = 1000000007;
const usz MAX_INPUT_LENGTH = 24;

fn void multiply_matrix(long* left, long* right, long* output, usz dimension) {
    for (usz row = 0; row < dimension; row += 1) {
        for (usz column = 0; column < dimension; column += 1) {
            long value = 0;
            for (usz inner = 0; inner < dimension; inner += 1) {
                value = (value + (left[row * dimension + inner] % MODULUS) *
                                 (right[inner * dimension + column] % MODULUS) % MODULUS) % MODULUS;
            }
            output[row * dimension + column] = value;
        }
    }
}

fn long linear_recurrence_matrix(long* input, usz length) @export("linear_recurrence_matrix") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long dimension_value = input[0];
    long nth_term = input[1];
    long constant_or_sum_included = input[2];
    if (dimension_value < 1 || dimension_value > 4 || nth_term < 0 || nth_term > 1000000 ||
        (constant_or_sum_included != 0 && constant_or_sum_included != 1)) return -1;
    usz dimension = (usz)dimension_value;
    usz matrix_count = dimension * dimension;
    if (length != 3 + matrix_count + dimension) return -1;
    if (constant_or_sum_included == 1 && nth_term < dimension_value - 1) return -1;

    long[16] matrix;
    long[4] base_row;
    for (usz index = 0; index < matrix_count + dimension; index += 1) {
        long value = input[3 + index];
        if (value < 0 || value >= MODULUS) return -1;
        if (index < matrix_count) {
            matrix[index] = value;
        } else {
            base_row[index - matrix_count] = value;
        }
    }
    if (nth_term < dimension_value - constant_or_sum_included) {
        return base_row[(usz)(nth_term - constant_or_sum_included)];
    }

    bool matrix_is_zero = true;
    for (usz index = 0; index < matrix_count; index += 1) {
        if (matrix[index] != 0) matrix_is_zero = false;
    }
    if (matrix_is_zero) return 0;

    long[16] result;
    long[16] work;
    for (usz index = 0; index < matrix_count; index += 1) {
        result[index] = 0;
        work[index] = 0;
    }
    for (usz index = 0; index < dimension; index += 1) result[index * dimension + index] = 1;
    long power = nth_term - dimension_value + 1 + constant_or_sum_included;
    while (power > 0) {
        if (power % 2 == 1) {
            multiply_matrix(&result[0], &matrix[0], &work[0], dimension);
            for (usz index = 0; index < matrix_count; index += 1) result[index] = work[index];
        }
        power /= 2;
        multiply_matrix(&matrix[0], &matrix[0], &work[0], dimension);
        for (usz index = 0; index < matrix_count; index += 1) matrix[index] = work[index];
    }

    long value = 0;
    for (usz index = 0; index < dimension; index += 1) {
        value = (value + base_row[index] * result[index * dimension + dimension - 1] % MODULUS) % MODULUS;
    }
    return value;
}
