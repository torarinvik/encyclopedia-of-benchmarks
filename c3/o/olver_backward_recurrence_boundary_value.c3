module olver_backward_recurrence_boundary_value;

const usz MAX_PARSEABLE_INPUT_LENGTH = 53;
const long MAX_NMAX = 12;

fn bool finite(double value) { return value == value && value <= 1.7976931348623157e308 && value >= -1.7976931348623157e308; }

fn bool exact_integer(double value, long low, long high, long* decoded) {
    if (!finite(value) || value < (double)low || value > (double)high || (double)(long)value != value) return false;
    *decoded = (long)value;
    return true;
}

fn long olver_backward_recurrence_boundary_value(double* input, usz input_length,
    double* output, usz output_capacity) @export("olver_backward_recurrence_boundary_value") {
    if (input == null || input_length < 8 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    for (usz i = 0; i < input_length; i++) if (!finite(input[i])) return -1L;
    long m, nmax;
    if (!exact_integer(input[0], 1, 8, &m) || !exact_integer(input[1], 1, MAX_NMAX, &nmax) ||
        m > nmax || input_length != (usz)(4 + 4 * nmax)) return -1L;
    if (input[2] < 9.094947017729282e-13 || input[2] > 0.5 || input[3] < -16.0 || input[3] > 16.0) return -1L;
    for (long i = 0; i < nmax; i++) {
        if (input[4+i] < -16.0 || input[4+i] > 16.0 || (input[4+i] > -0.0625 && input[4+i] < 0.0625) ||
            input[4+nmax+i] < -16.0 || input[4+nmax+i] > 16.0 ||
            input[4+2*nmax+i] < -16.0 || input[4+2*nmax+i] > 16.0 ||
            input[4+3*nmax+i] < -16.0 || input[4+3*nmax+i] > 16.0) return -1L;
    }
    usz required = (usz)(m + 2);
    if (output == null || output_capacity < required) return -2L;

    double p[14] = {0};
    double e[13] = {0};
    double w[13] = {0};
    p[1] = 1.0;
    e[0] = input[3];
    for (long n = 1; n <= m; n++) {
        double a = input[4+n-1];
        double b = input[4+nmax+n-1];
        double c = input[4+2*nmax+n-1];
        double d = input[4+3*nmax+n-1];
        p[n+1] = (b*p[n]-c*p[n-1])/a;
        e[n] = (c*e[n-1]-d*p[n])/a;
        if (!finite(p[n+1]) || !finite(e[n])) return -3L;
    }
    for (long n = 1; n <= m; n++) {
        double product = p[n]*p[n+1];
        if (product == 0.0 || !finite(product) || !finite(e[n]/product)) return -3L;
    }
    double minimum = e[1]/(p[1]*p[2]);
    if (minimum < 0.0) minimum = -minimum;
    for (long n = 2; n <= m; n++) {
        double ratio = e[n]/(p[n]*p[n+1]);
        if (ratio < 0) ratio = -ratio;
        if (ratio < minimum) minimum = ratio;
    }
    double threshold = input[2]*minimum;
    long endpoint = 0;
    for (long n = m; n <= nmax; n++) {
        if (n > m) {
            double a = input[4+n-1];
            double b = input[4+nmax+n-1];
            double c = input[4+2*nmax+n-1];
            double d = input[4+3*nmax+n-1];
            p[n+1] = (b*p[n]-c*p[n-1])/a;
            e[n] = (c*e[n-1]-d*p[n])/a;
            if (!finite(p[n+1]) || !finite(e[n])) return -3L;
        }
        double product = p[n]*p[n+1];
        if (product == 0.0 || !finite(product)) return -3L;
        double ratio = e[n]/product;
        if (ratio < 0) ratio = -ratio;
        if (!finite(ratio)) return -3L;
        if (ratio <= threshold) { endpoint = n; break; }
    }
    if (endpoint == 0) return -3L;
    for (long n = endpoint-1; n >= 0; n--) {
        w[n] = (p[n]*w[n+1]+e[n])/p[n+1];
        if (!finite(w[n])) return -3L;
    }
    output[0] = (double)endpoint;
    for (long i = 0; i <= m; i++) output[i+1] = w[i];
    return (long)required;
}
