module smo_dual_pair_update;

const int MAX_N = 8;
const int MAX_D = 3;
const usz MAX_INPUT = 47;

fn bool field(double x, long low, long high) {
    return x == x && x >= (double)low && x <= (double)high && (double)(long)x == x;
}

fn double dot(double* a, double* b, int d) {
    double sum = 0.0;
    for (int r = 0; r < d; ++r) sum += a[r] * b[r];
    return sum;
}

fn double objective(double* alpha, int* labels, double* x, int n, int d) {
    double sum = 0.0;
    for (int p = 0; p < n; ++p) sum += alpha[p];
    for (int p = 0; p < n; ++p)
        for (int q = 0; q < n; ++q)
            sum -= 0.5 * alpha[p] * alpha[q] * (double)(labels[p] * labels[q]) *
                   dot(&x[p * MAX_D], &x[q * MAX_D], d);
    return sum;
}

fn long smo_dual_pair_update(double* input, usz input_length,
                             double* output, usz output_capacity)
    @export("smo_dual_pair_update") {
    if (input == null || input_length < 6 || input_length > MAX_INPUT) return -1L;
    if (!field(input[0], 2, MAX_N) || !field(input[1], 1, MAX_D) ||
        !field(input[2], 1, 5000) || !field(input[3], -1000000, 1000000)) return -1L;
    int n = (int)input[0];
    int d = (int)input[1];
    int c_milli = (int)input[2];
    int b_milli = (int)input[3];
    if (input_length != (usz)(6 + 2 * n + n * d)) return -1L;

    int[MAX_N] labels;
    double[MAX_N] alpha;
    double[MAX_N * MAX_D] x;
    bool negative = false;
    bool positive = false;
    int equality = 0;
    usz at = 4;
    for (int k = 0; k < n; ++k) {
        if (!field(input[at], -1, 1) || input[at] == 0.0) return -1L;
        labels[k] = (int)input[at];
        if (labels[k] < 0) negative = true;
        else positive = true;
        at += 1;
    }
    for (int k = 0; k < n; ++k) {
        if (!field(input[at], 0, c_milli)) return -1L;
        int value = (int)input[at];
        alpha[k] = (double)value / 1000.0;
        equality += labels[k] * value;
        at += 1;
    }
    if (!negative || !positive || equality != 0) return -1L;
    for (int k = 0; k < n; ++k)
        for (int r = 0; r < d; ++r) {
            if (!field(input[at], -32, 32)) return -1L;
            x[k * MAX_D + r] = input[at];
            at += 1;
        }
    if (!field(input[at], 0, n - 1) || !field(input[at + 1], 0, n - 1)) return -1L;
    int i = (int)input[at];
    int j = (int)input[at + 1];
    if (i == j) return -1L;
    if (output == null || output_capacity < (usz)(n + 1)) return -2L;

    double c_value = (double)c_milli / 1000.0;
    double bias = (double)b_milli / 1000.0;
    int yi = labels[i], yj = labels[j], sign = yi * yj;
    double old_i = alpha[i], old_j = alpha[j];
    double kii = dot(&x[i * MAX_D], &x[i * MAX_D], d);
    double kjj = dot(&x[j * MAX_D], &x[j * MAX_D], d);
    double kij = dot(&x[i * MAX_D], &x[j * MAX_D], d);
    double error_i = bias - (double)yi;
    double error_j = bias - (double)yj;
    for (int k = 0; k < n; ++k) {
        error_i += alpha[k] * (double)labels[k] * dot(&x[k * MAX_D], &x[i * MAX_D], d);
        error_j += alpha[k] * (double)labels[k] * dot(&x[k * MAX_D], &x[j * MAX_D], d);
    }
    double low, high;
    if (yi != yj) {
        low = old_j - old_i > 0.0 ? old_j - old_i : 0.0;
        high = c_value < c_value + old_j - old_i ? c_value : c_value + old_j - old_i;
    } else {
        low = old_i + old_j - c_value > 0.0 ? old_i + old_j - c_value : 0.0;
        high = c_value < old_i + old_j ? c_value : old_i + old_j;
    }
    double eta = 2.0 * kij - kii - kjj;
    double new_j;
    if (eta < 0.0) {
        new_j = old_j - (double)yj * (error_i - error_j) / eta;
        if (new_j < low) new_j = low;
        if (new_j > high) new_j = high;
    } else {
        double[MAX_N] candidate;
        for (int k = 0; k < n; ++k) candidate[k] = alpha[k];
        candidate[i] = old_i + (double)sign * (old_j - low);
        candidate[j] = low;
        double low_score = objective(&candidate[0], &labels[0], &x[0], n, d);
        candidate[i] = old_i + (double)sign * (old_j - high);
        candidate[j] = high;
        double high_score = objective(&candidate[0], &labels[0], &x[0], n, d);
        new_j = high_score > low_score ? high : low;
    }
    double new_i = old_i + (double)sign * (old_j - new_j);
    double delta_i = new_i - old_i, delta_j = new_j - old_j;
    double bias_i = bias - error_i - (double)yi * delta_i * kii - (double)yj * delta_j * kij;
    double bias_j = bias - error_j - (double)yi * delta_i * kij - (double)yj * delta_j * kjj;
    double new_bias = (new_i > 0.0 && new_i < c_value) ? bias_i :
                      (new_j > 0.0 && new_j < c_value) ? bias_j : 0.5 * (bias_i + bias_j);
    alpha[i] = new_i;
    alpha[j] = new_j;
    for (int k = 0; k < n; ++k) output[k] = alpha[k];
    output[n] = new_bias;
    return (long)(n + 1);
}
