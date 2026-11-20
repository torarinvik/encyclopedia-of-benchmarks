module smo_deterministic_training;

const int MAX_N = 8;
const int MAX_D = 3;
const usz MAX_INPUT = 37;
const double TOL = 0.001;
const double EPS = 0.001;

extern fn double fabs(double value);

fn bool field(double value, long low, long high) {
    return value == value && value >= (double)low && value <= (double)high &&
           (double)(long)value == value;
}

fn double dot(double* x, int a, int b, int d) {
    double value = 0.0;
    for (int k = 0; k < d; ++k) value += x[a * MAX_D + k] * x[b * MAX_D + k];
    return value;
}

fn double decision(int index, double* alpha, double bias, int* labels,
                   double* x, int n, int d) {
    double value = bias;
    for (int k = 0; k < n; ++k)
        value += alpha[k] * (double)labels[k] * dot(x, k, index, d);
    return value;
}

fn double dual(double* alpha, int* labels, double* x, int n, int d) {
    double value = 0.0;
    for (int i = 0; i < n; ++i) value += alpha[i];
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            value -= 0.5 * alpha[i] * alpha[j] * (double)(labels[i] * labels[j]) * dot(x, i, j, d);
    return value;
}

fn bool take_step(int i, int j, double* alpha, double* bias, double c,
                  int* labels, double* x, int n, int d) {
    if (i == j) return false;
    int yi = labels[i], yj = labels[j], sign = yi * yj;
    double old_i = alpha[i], old_j = alpha[j];
    double e_i = decision(i, alpha, *bias, labels, x, n, d) - (double)yi;
    double e_j = decision(j, alpha, *bias, labels, x, n, d) - (double)yj;
    double low, high;
    if (yi != yj) {
        low = old_j - old_i > 0.0 ? old_j - old_i : 0.0;
        high = c < c + old_j - old_i ? c : c + old_j - old_i;
    } else {
        low = old_i + old_j - c > 0.0 ? old_i + old_j - c : 0.0;
        high = c < old_i + old_j ? c : old_i + old_j;
    }
    if (low == high) return false;
    double kii = dot(x, i, i, d), kjj = dot(x, j, j, d), kij = dot(x, i, j, d);
    double curvature = kii + kjj - 2.0 * kij;
    double new_j;
    if (curvature > 0.0) {
        new_j = old_j + (double)yj * (e_i - e_j) / curvature;
        if (new_j < low) new_j = low;
        if (new_j > high) new_j = high;
    } else {
        double[MAX_N] trial;
        for (int k = 0; k < n; ++k) trial[k] = alpha[k];
        trial[i] = old_i + (double)sign * (old_j - low);
        trial[j] = low;
        double low_score = dual(&trial[0], labels, x, n, d);
        trial[i] = old_i + (double)sign * (old_j - high);
        trial[j] = high;
        double high_score = dual(&trial[0], labels, x, n, d);
        if (low_score > high_score + EPS) new_j = low;
        else if (high_score > low_score + EPS) new_j = high;
        else new_j = old_j;
    }
    if (fabs(new_j - old_j) < EPS * (new_j + old_j + EPS)) return false;
    double new_i = old_i + (double)sign * (old_j - new_j);
    double di = new_i - old_i, dj = new_j - old_j;
    double b_i = *bias - e_i - (double)yi * di * kii - (double)yj * dj * kij;
    double b_j = *bias - e_j - (double)yi * di * kij - (double)yj * dj * kjj;
    if (new_i > 0.0 && new_i < c) *bias = b_i;
    else if (new_j > 0.0 && new_j < c) *bias = b_j;
    else *bias = 0.5 * (b_i + b_j);
    alpha[i] = new_i;
    alpha[j] = new_j;
    return true;
}

fn bool examine(int j, double* alpha, double* bias, double c,
                int* labels, double* x, int n, int d) {
    double e_j = decision(j, alpha, *bias, labels, x, n, d) - (double)labels[j];
    double r = e_j * (double)labels[j];
    if (!((r < -TOL && alpha[j] < c) || (r > TOL && alpha[j] > 0.0))) return false;
    int free_count = 0, best = -1;
    double best_gap = -1.0;
    for (int i = 0; i < n; ++i) {
        if (alpha[i] > 0.0 && alpha[i] < c) {
            ++free_count;
            double e_i = decision(i, alpha, *bias, labels, x, n, d) - (double)labels[i];
            double gap = fabs(e_i - e_j);
            if (gap > best_gap) { best_gap = gap; best = i; }
        }
    }
    if (free_count > 1 && take_step(best, j, alpha, bias, c, labels, x, n, d)) return true;
    for (int i = 0; i < n; ++i)
        if (alpha[i] > 0.0 && alpha[i] < c && take_step(i, j, alpha, bias, c, labels, x, n, d)) return true;
    for (int i = 0; i < n; ++i)
        if (take_step(i, j, alpha, bias, c, labels, x, n, d)) return true;
    return false;
}

fn long smo_deterministic_training(double* input, usz input_length,
                                  double* output, usz output_capacity)
    @export("smo_deterministic_training") {
    if (input == null || input_length < 4 || input_length > MAX_INPUT) return -1L;
    if (!field(input[0], 2, MAX_N) || !field(input[1], 1, MAX_D) ||
        !field(input[2], 1, 5000) || !field(input[3], 1, 16)) return -1L;
    int n = (int)input[0], d = (int)input[1], c_milli = (int)input[2], cap = (int)input[3];
    if (input_length != (usz)(4 + n + n * d)) return -1L;
    int[MAX_N] labels;
    double[MAX_N] alpha;
    double[MAX_N * MAX_D] x;
    bool positive = false, negative = false;
    for (int i = 0; i < MAX_N; ++i) alpha[i] = 0.0;
    for (int i = 0; i < MAX_N * MAX_D; ++i) x[i] = 0.0;
    usz at = 4;
    for (int i = 0; i < n; ++i) {
        if (!field(input[at], -1, 1) || input[at] == 0.0) return -1L;
        labels[i] = (int)input[at];
        if (labels[i] > 0) positive = true; else negative = true;
        at += 1;
    }
    if (!positive || !negative) return -1L;
    for (int i = 0; i < n; ++i)
        for (int k = 0; k < d; ++k) {
            if (!field(input[at], -32, 32)) return -1L;
            x[i * MAX_D + k] = input[at];
            at += 1;
        }
    if (output == null || output_capacity < (usz)(n + 4)) return -2L;

    double bias = 0.0, c = (double)c_milli / 1000.0;
    int changed = 0, examine_all = 1, passes = 0;
    while (passes < cap && (changed > 0 || examine_all != 0)) {
        changed = 0;
        for (int j = 0; j < n; ++j)
            if ((examine_all != 0 || (alpha[j] > 0.0 && alpha[j] < c)) &&
                examine(j, &alpha[0], &bias, c, &labels[0], &x[0], n, d)) ++changed;
        ++passes;
        if (examine_all != 0) examine_all = 0;
        else if (changed == 0) examine_all = 1;
    }
    double[MAX_N + 4] staged;
    staged[0] = (double)passes;
    staged[1] = (double)changed;
    staged[2] = (passes < cap && changed == 0 && examine_all == 0) ? 1.0 : 0.0;
    for (int i = 0; i < n; ++i) staged[3 + i] = alpha[i];
    staged[3 + n] = bias;
    for (int i = 0; i < n + 4; ++i) output[i] = staged[i];
    return (long)(n + 4);
}
