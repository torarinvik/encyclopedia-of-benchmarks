module local_weighted_learning;
extern fn double exp(double value);

const usz MAX_N = 16;
const usz MAX_D = 4;
const usz MAX_PARSEABLE_INPUT_LENGTH = 84;
const double PIVOT_FLOOR = 0.000003814697265625;

bool bounded_integer(double value, long minimum, long maximum, long* result) {
    if (value != value || value < (double)minimum || value > (double)maximum) return false;
    long integer = (long)value;
    if ((double)integer != value) return false;
    *result = integer;
    return true;
}

bool grid_value(double value, double minimum, double maximum) {
    if (value != value || value < minimum || value > maximum) return false;
    double scaled = value * 16.0;
    return scaled == (double)(long)scaled;
}

bool finite_value(double value) {
    return value == value && value > -1.0e300 && value < 1.0e300;
}

fn long local_weighted_learning(double* input, usz input_length, double* output, usz output_capacity)
    @export("local_weighted_learning") {
    if (input == null || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    long n_value, d_value;
    if (!bounded_integer(input[0], 2, (long)MAX_N, &n_value) ||
        !bounded_integer(input[1], 1, (long)MAX_D, &d_value)) return -1L;
    if (d_value > n_value) return -1L;
    usz n = (usz)n_value;
    usz d = (usz)d_value;
    double tau = input[2];
    if (!grid_value(tau, 2.0, 8.0)) return -1L;
    usz expected_length = 3 + n * d + n;
    if (input_length != expected_length) return -1L;

    double[MAX_N][MAX_D] x_train = zeroed;
    double[MAX_N] y_train = zeroed;
    usz cursor = 3;
    for (usz row = 0; row < n; row++) {
        for (usz feature = 0; feature < d; feature++) {
            double value = input[cursor++];
            if (!grid_value(value, -4.0, 4.0)) return -1L;
            x_train[row][feature] = value;
        }
    }
    for (usz row = 0; row < n; row++) {
        double value = input[cursor++];
        if (!grid_value(value, -8.0, 8.0)) return -1L;
        y_train[row] = value;
    }

    double[MAX_N] staged = zeroed;
    for (usz query = 0; query < n; query++) {
        double[MAX_N] weights = zeroed;
        for (usz row = 0; row < n; row++) {
            double distance_squared = 0.0;
            for (usz feature = 0; feature < d; feature++) {
                double delta = x_train[query][feature] - x_train[row][feature];
                double squared_delta = delta * delta;
                distance_squared = distance_squared + squared_delta;
            }
            double tau_squared = tau * tau;
            double denominator = (-2.0) * tau_squared;
            double exponent = distance_squared / denominator;
            weights[row] = exp(exponent);
            if (!finite_value(weights[row]) || weights[row] <= 0.0) return -1L;
        }

        double[MAX_D][MAX_D] normal = zeroed;
        double[MAX_D] rhs = zeroed;
        for (usz row = 0; row < n; row++) {
            double[MAX_D] weighted_x = zeroed;
            for (usz feature = 0; feature < d; feature++)
                weighted_x[feature] = weights[row] * x_train[row][feature];
            double weighted_y = weights[row] * y_train[row];
            for (usz p = 0; p < d; p++) {
                double rhs_product = x_train[row][p] * weighted_y;
                rhs[p] = rhs[p] + rhs_product;
                for (usz q = 0; q < d; q++) {
                    double product = x_train[row][p] * weighted_x[q];
                    normal[p][q] = normal[p][q] + product;
                }
            }
        }

        double scale = 0.0;
        for (usz index = 0; index < d; index++) {
            double diagonal = normal[index][index];
            if (!finite_value(diagonal)) return -1L;
            if (diagonal < 0.0) diagonal = 0.0 - diagonal;
            if (diagonal > scale) scale = diagonal;
        }
        if (scale == 0.0 || !finite_value(scale)) return -1L;

        for (usz pivot_column = 0; pivot_column < d; pivot_column++) {
            usz pivot_row = pivot_column;
            double pivot_magnitude = normal[pivot_row][pivot_column];
            if (pivot_magnitude < 0.0) pivot_magnitude = 0.0 - pivot_magnitude;
            for (usz candidate = pivot_column + 1; candidate < d; candidate++) {
                double candidate_magnitude = normal[candidate][pivot_column];
                if (!finite_value(candidate_magnitude)) return -1L;
                if (candidate_magnitude < 0.0) candidate_magnitude = 0.0 - candidate_magnitude;
                if (candidate_magnitude > pivot_magnitude) {
                    pivot_row = candidate;
                    pivot_magnitude = candidate_magnitude;
                }
            }
            if (!finite_value(pivot_magnitude) || pivot_magnitude <= PIVOT_FLOOR * scale) return -1L;
            if (pivot_row != pivot_column) {
                for (usz column = 0; column < d; column++) {
                    double temporary = normal[pivot_column][column];
                    normal[pivot_column][column] = normal[pivot_row][column];
                    normal[pivot_row][column] = temporary;
                }
                double temporary = rhs[pivot_column];
                rhs[pivot_column] = rhs[pivot_row];
                rhs[pivot_row] = temporary;
            }
            double pivot = normal[pivot_column][pivot_column];
            for (usz row = pivot_column + 1; row < d; row++) {
                double factor = normal[row][pivot_column] / pivot;
                if (!finite_value(factor)) return -1L;
                normal[row][pivot_column] = 0.0;
                for (usz column = pivot_column + 1; column < d; column++) {
                    double product = factor * normal[pivot_column][column];
                    normal[row][column] = normal[row][column] - product;
                    if (!finite_value(normal[row][column])) return -1L;
                }
                double product = factor * rhs[pivot_column];
                rhs[row] = rhs[row] - product;
                if (!finite_value(rhs[row])) return -1L;
            }
        }

        double[MAX_D] coefficients = zeroed;
        usz reverse_index = d;
        while (reverse_index > 0) {
            reverse_index--;
            usz row = reverse_index;
            double residual = rhs[row];
            for (usz column = row + 1; column < d; column++) {
                double product = normal[row][column] * coefficients[column];
                residual = residual - product;
            }
            double diagonal = normal[row][row];
            if (!finite_value(residual) || diagonal == 0.0 || !finite_value(diagonal)) return -1L;
            coefficients[row] = residual / diagonal;
            if (!finite_value(coefficients[row])) return -1L;
        }

        double prediction = 0.0;
        for (usz feature = 0; feature < d; feature++) {
            double product = x_train[query][feature] * coefficients[feature];
            prediction = prediction + product;
        }
        if (!finite_value(prediction)) return -1L;
        staged[query] = prediction;
    }

    if (output == null || output_capacity < n) return -2L;
    for (usz index = 0; index < n; index++) output[index] = staged[index];
    return (long)n;
}
