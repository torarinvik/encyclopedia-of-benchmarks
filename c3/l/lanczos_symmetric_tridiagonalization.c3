module lanczos_symmetric_tridiagonalization;
extern fn double sqrt(double value);

const usz MAX_PARSEABLE_INPUT_LENGTH = 19;
const long MAX_ORDER = 4;

fn bool finite(double value) {
    return value == value && value <= 1.7976931348623157e308 && value >= -1.7976931348623157e308;
}

fn bool exact_integer(double value, long low, long high, long* decoded) {
    if (!finite(value) || value < (double)low || value > (double)high || (double)(long)value != value) return false;
    *decoded = (long)value;
    return true;
}

fn long lanczos_symmetric_tridiagonalization(double* input, usz input_length,
    double* output, usz output_capacity) @export("lanczos_symmetric_tridiagonalization") {
    if (input == null || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    for (usz i = 0; i < input_length; i++) if (!finite(input[i])) return -1L;
    long n, k;
    if (!exact_integer(input[0], 1, MAX_ORDER, &n) || !exact_integer(input[1], 1, MAX_ORDER, &k) ||
        k > n || input_length != (usz)(2 + n * n)) return -1L;
    for (long row = 0; row < n; row++) {
        for (long col = 0; col < n; col++) {
            long entry;
            if (!exact_integer(input[2 + row*n + col], -4, 4, &entry) ||
                input[2 + row*n + col] != input[2 + col*n + row]) return -1L;
        }
    }
    usz required = (usz)(2 * k);
    if (output == null || output_capacity < required) return -2L;

    double previous[4] = {0};
    double current[4] = {0};
    double product[4] = {0};
    double residual[4] = {0};
    double next[4] = {0};
    double diagonal[4] = {0};
    double off_diagonal[3] = {0};
    current[0] = 1.0;
    double previous_beta = 0.0;
    for (long step = 0; step < k; step++) {
        for (long row = 0; row < n; row++) {
            product[row] = 0.0;
            for (long col = 0; col < n; col++)
                product[row] += input[2 + row*n + col] * current[col];
        }
        double alpha = 0.0;
        for (long index = 0; index < n; index++) alpha += current[index] * product[index];
        if (!finite(alpha)) return -3L;
        diagonal[step] = alpha;
        if (step + 1 == k) break;
        double norm_squared = 0.0;
        for (long index = 0; index < n; index++) {
            residual[index] = product[index] - alpha * current[index] - previous_beta * previous[index];
            norm_squared += residual[index] * residual[index];
        }
        if (!finite(norm_squared) || norm_squared < 0.0) return -3L;
        double beta = sqrt(norm_squared);
        if (!finite(beta) || beta <= 9.094947017729282e-13) return -3L;
        off_diagonal[step] = beta;
        for (long index = 0; index < n; index++) next[index] = residual[index] / beta;
        for (long index = 0; index < n; index++) previous[index] = current[index];
        for (long index = 0; index < n; index++) current[index] = next[index];
        previous_beta = beta;
    }
    output[0] = (double)k;
    for (long index = 0; index < k; index++) output[1 + index] = diagonal[index];
    for (long index = 0; index < k - 1; index++) output[1 + k + index] = off_diagonal[index];
    return (long)required;
}
