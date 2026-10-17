module inverse_of_matrix;

const usz MAX_INPUT_VALUES = 11;
const usz MAX_OUTPUT_BYTES = 72;
const long INVALID_RESULT = -1;
const long OUTPUT_ERROR = -2;
const long COEFFICIENT_LIMIT = 32;

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn double rounded_subtract(double left, double right) @noinline {
    return left - right;
}

fn double rounded_divide(double left, double right) @noinline {
    return left / right;
}

fn double absolute_double(double value) {
    return value < 0.0 ? -value : value;
}

fn long absolute_coefficient(long value) {
    return value < 0 ? -value : value;
}

fn bool valid_dominance(long* matrix, usz dimension) {
    int dominant_column[3] = {-1, -1, -1};
    int column_seen[3] = {0, 0, 0};
    for (usz row = 0; row < dimension; row++) {
        for (usz column = 0; column < dimension; column++) {
            long other_sum = 0;
            for (usz other = 0; other < dimension; other++) {
                if (other != column)
                    other_sum += absolute_coefficient(matrix[row * dimension + other]);
            }
            if (absolute_coefficient(matrix[row * dimension + column]) > other_sum) {
                if (dominant_column[row] != -1) return false;
                dominant_column[row] = (int)column;
            }
        }
        if (dominant_column[row] == -1 || column_seen[dominant_column[row]] != 0)
            return false;
        column_seen[dominant_column[row]] = 1;
    }
    return true;
}

fn bool scaled_pivot_inverse(double* matrix, usz dimension, double* inverse) {
    double a[9] = {0.0};
    double b[9] = {0.0};
    double scale[3] = {0.0, 0.0, 0.0};
    int index[3] = {0, 1, 2};
    for (usz row = 0; row < dimension; row++) {
        for (usz column = 0; column < dimension; column++) {
            a[row * dimension + column] = matrix[row * dimension + column];
            if (row == column) b[row * dimension + column] = 1.0;
            double magnitude = absolute_double(a[row * dimension + column]);
            if (magnitude > scale[row]) scale[row] = magnitude;
        }
        if (scale[row] == 0.0) return false;
    }

    for (usz column = 0; column + 1 < dimension; column++) {
        double best_ratio = 0.0;
        usz best = column;
        for (usz row = column; row < dimension; row++) {
            double ratio = rounded_divide(
                absolute_double(a[(usz)index[row] * dimension + column]),
                scale[index[row]]);
            if (ratio > best_ratio) {
                best_ratio = ratio;
                best = row;
            }
        }

        int temporary = index[column];
        index[column] = index[best];
        index[best] = temporary;
        usz pivot_row = (usz)index[column];
        double pivot = a[pivot_row * dimension + column];
        if (pivot == 0.0) return false;

        for (usz row = column + 1; row < dimension; row++) {
            usz current_row = (usz)index[row];
            double factor = rounded_divide(a[current_row * dimension + column], pivot);
            a[current_row * dimension + column] = factor;
            for (usz trailing = column + 1; trailing < dimension; trailing++) {
                double product = rounded_multiply(factor, a[pivot_row * dimension + trailing]);
                a[current_row * dimension + trailing] = rounded_subtract(
                    a[current_row * dimension + trailing], product);
            }
        }
    }

    for (usz row = 0; row + 1 < dimension; row++) {
        usz current_row = (usz)index[row];
        for (usz lower = row + 1; lower < dimension; lower++) {
            usz lower_row = (usz)index[lower];
            for (usz column = 0; column < dimension; column++) {
                double product = rounded_multiply(
                    a[lower_row * dimension + row], b[current_row * dimension + column]);
                b[lower_row * dimension + column] = rounded_subtract(
                    b[lower_row * dimension + column], product);
            }
        }
    }

    for (usz column = 0; column < dimension; column++) {
        usz last_row = (usz)index[dimension - 1];
        double last_pivot = a[last_row * dimension + dimension - 1];
        if (last_pivot == 0.0) return false;
        inverse[(dimension - 1) * dimension + column] = rounded_divide(
            b[last_row * dimension + column], last_pivot);

        for (int step = (int)dimension - 2; step >= 0; step--) {
            usz current_row = (usz)index[step];
            double value = b[current_row * dimension + column];
            for (usz trailing = (usz)step + 1; trailing < dimension; trailing++) {
                double product = rounded_multiply(
                    a[current_row * dimension + trailing],
                    inverse[trailing * dimension + column]);
                value = rounded_subtract(value, product);
            }
            double pivot = a[current_row * dimension + (usz)step];
            if (pivot == 0.0) return false;
            inverse[(usz)step * dimension + column] = rounded_divide(value, pivot);
        }
    }

    for (usz i = 0; i < dimension * dimension; i++) {
        double value = inverse[i];
        if (value != value || value < -1.0e300 || value > 1.0e300) return false;
    }
    return true;
}

fn void store_little_endian_double(uint8* output, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++)
        output[byte] = (uint8)(bits >> (byte * 8));
}

fn long inverse_of_matrix(long* input, usz input_length, uint8* output,
                          usz output_capacity) @export("inverse_of_matrix") {
    if (input == null || input_length < 1 || input_length > MAX_INPUT_VALUES)
        return INVALID_RESULT;
    if (input[0] != 2 && input[0] != 3) return INVALID_RESULT;
    usz dimension = (usz)input[0];
    if (input_length != 1 + dimension * dimension) return INVALID_RESULT;

    long matrix_q[9] = {0};
    double matrix[9] = {0.0};
    for (usz index = 0; index < dimension * dimension; index++) {
        long value = input[index + 1];
        if (value < -COEFFICIENT_LIMIT || value > COEFFICIENT_LIMIT)
            return INVALID_RESULT;
        matrix_q[index] = value;
        matrix[index] = (double)value / 16.0;
    }
    if (!valid_dominance(matrix_q, dimension)) return INVALID_RESULT;

    double inverse[9] = {0.0};
    if (!scaled_pivot_inverse(matrix, dimension, inverse)) return INVALID_RESULT;

    usz output_bytes = dimension * dimension * 8;
    uint8 encoded[MAX_OUTPUT_BYTES] = {0};
    for (usz index = 0; index < dimension * dimension; index++)
        store_little_endian_double(&encoded[index * 8], inverse[index]);

    if (output == null || output_capacity < output_bytes) return OUTPUT_ERROR;
    for (usz index = 0; index < output_bytes; index++) output[index] = encoded[index];
    return (long)output_bytes;
}
