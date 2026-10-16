module iqr_outlier_indices;

const usz MAX_LENGTH = 62;
const long INVALID_RESULT = -1L;

fn double type7_quantile(long* sorted, usz count, double probability) {
    double h = (double)(count - 1) * probability + 1.0;
    usz order = (usz)h;
    double fraction = h - (double)order;
    usz lower = order - 1;
    if (fraction == 0.0 || lower + 1 >= count) return (double)sorted[lower];
    return (1.0 - fraction) * (double)sorted[lower] + fraction * (double)sorted[lower + 1];
}

fn long iqr_outlier_indices(long* values, usz length) @export("iqr_outlier_indices") {
    if (values == null || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    long[MAX_LENGTH] sorted;
    for (usz i = 0; i < length; i++) {
        if (values[i] < -1000000 || values[i] > 1000000) return INVALID_RESULT;
        usz j = i;
        while (j > 0 && sorted[j - 1] > values[i]) { sorted[j] = sorted[j - 1]; j--; }
        sorted[j] = values[i];
    }
    double q1 = type7_quantile(&sorted[0], length, 0.25);
    double q3 = type7_quantile(&sorted[0], length, 0.75);
    double iqr = q3 - q1;
    double lower_bound = q1 - 1.5 * iqr;
    double upper_bound = q3 + 1.5 * iqr;
    ulong mask = 0;
    for (usz i = 0; i < length; i++) {
        if ((double)values[i] < lower_bound || (double)values[i] > upper_bound) mask |= 1UL << i;
    }
    return (long)mask;
}
