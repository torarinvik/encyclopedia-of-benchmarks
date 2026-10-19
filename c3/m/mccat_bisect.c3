module mccat_bisect;

const usz MAX_N = 32;
const usz MAX_OUTPUT_BYTES = (MAX_N + 1) * 8;
const double EPSILON = 2.2204460492503131e-16;

fn double abs_value(double value) { return value < 0.0 ? -value : value; }

fn int sturm(usz n, double* diagonal, double* off_diagonal, double* beta, double x) {
    int negative_count = 0;
    double q = 1.0;
    for (usz i = 0; i < n; i++) {
        if (q != 0.0) q = (diagonal[i] - x) - beta[i] / q;
        else q = (diagonal[i] - x) - abs_value(off_diagonal[i]) / EPSILON;
        if (q < 0.0) negative_count++;
    }
    return negative_count;
}

fn void store_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz i = 0; i < 8; i++) { output[offset + i] = (char)(bits & 255); bits >>= 8; }
}

fn usz solve(int n, char* output) {
    double[MAX_N] diagonal = {};
    double[MAX_N] off_diagonal = {};
    double[MAX_N] beta = {};
    double[MAX_N + 1] eigenvalues = {};
    double[MAX_N + 1] lower_bounds = {};
    for (int i = 0; i < n; i++) {
        double value = (double)(i + 1);
        diagonal[i] = value * value;
        diagonal[i] = diagonal[i] * diagonal[i];
        off_diagonal[i] = (double)i;
        beta[i] = off_diagonal[i] * off_diagonal[i];
    }
    beta[0] = 0.0;
    off_diagonal[0] = 0.0;

    const double fudge = 1.01;
    double xmin = diagonal[n - 1] - fudge * abs_value(off_diagonal[n - 1]);
    double xmax = diagonal[n - 1] + fudge * abs_value(off_diagonal[n - 1]);
    for (int i = n - 2; i >= 0; i--) {
        double h = fudge * (abs_value(off_diagonal[i]) + abs_value(off_diagonal[i + 1]));
        if (diagonal[i] + h > xmax) xmax = diagonal[i] + h;
        if (diagonal[i] - h < xmin) xmin = diagonal[i] - h;
    }
    double eps2 = EPSILON * (xmin + xmax > 0.0 ? xmax : -xmin);
    double eps1 = EPSILON;
    if (eps1 <= 0.0) eps1 = eps2;
    eps2 = 0.5 * eps1 + 7.0 * eps2;

    double x0 = xmax;
    for (int i = n; i >= 1; i--) { eigenvalues[i] = xmax; lower_bounds[i] = xmin; }
    int iterations = 0;
    for (int k = n; k >= 1; k--) {
        double xu = xmin;
        for (int i = k; i >= 1; i--) {
            if (xu < lower_bounds[i]) { xu = lower_bounds[i]; break; }
        }
        if (x0 > eigenvalues[k]) x0 = eigenvalues[k];
        double x1 = (xu + x0) / 2.0;
        while (x0 - xu > 2.0 * EPSILON * (abs_value(xu) + abs_value(x0)) + eps1) {
            iterations++;
            int count = sturm((usz)n, &diagonal[0], &off_diagonal[0], &beta[0], x1);
            if (count < k) {
                if (count < 1) { xu = x1; lower_bounds[1] = x1; }
                else {
                    xu = x1;
                    lower_bounds[count + 1] = x1;
                    if (eigenvalues[count] > x1) eigenvalues[count] = x1;
                }
            } else x0 = x1;
            x1 = (xu + x0) / 2.0;
        }
        eigenvalues[k] = (xu + x0) / 2.0;
    }

    usz used = 0;
    for (int i = 2; i <= n; i++) { store_f64_le(output, used, eigenvalues[i]); used += 8; }
    store_f64_le(output, used, eps2); used += 8;
    store_f64_le(output, used, (double)iterations); used += 8;
    return used;
}

long mccat_bisect(long* values, usz length, char* output, usz output_capacity)
    @export("mccat_bisect") {
    if (values == null || length != 1 || values[0] < 2 || values[0] > (long)MAX_N) return -1;
    usz required = ((usz)values[0] + 1) * 8;
    if (output == null || output_capacity < required) return -2;
    char[MAX_OUTPUT_BYTES] staged;
    usz used = solve((int)values[0], &staged[0]);
    for (usz i = 0; i < used; i++) output[i] = staged[i];
    return (long)used;
}
