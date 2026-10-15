module spearman_rank_correlation_coefficient;

extern fn double floor(double value);

const double INVALID_RESULT = -1.0e300;
const long MAX_N = 3;

fn void assign_ranks(long* data, usz n, double* ranks) {
    usz order[3];
    for (usz i = 0; i < n; i++) order[i] = i;
    for (usz i = 1; i < n; i++) {
        usz key = order[i];
        usz j = i;
        while (j > 0 && data[order[j - 1]] > data[key]) {
            order[j] = order[j - 1];
            j--;
        }
        order[j] = key;
    }
    usz i = 0;
    while (i < n) {
        usz j = i;
        while (j < n - 1 && data[order[j + 1]] == data[order[i]]) j++;
        double rank = ((double)i + (double)j) / 2.0 + 1.0;
        for (usz k = i; k <= j; k++) ranks[order[k]] = rank;
        i = j + 1;
    }
}

fn double round_tenth_ties_even(double value) {
    double scaled = value * 10.0;
    double lower = floor(scaled);
    double fraction = scaled - lower;
    double rounded = lower;
    if (fraction > 0.5 || (fraction == 0.5 && ((long)lower % 2) != 0)) rounded = lower + 1.0;
    return rounded / 10.0;
}

fn double spearman_rank_correlation_coefficient(long* values, usz length) @export("spearman_rank_correlation_coefficient") {
    if (values == null || length < 5) return INVALID_RESULT;
    long n_value = values[0];
    if (n_value < 2 || n_value > MAX_N || length != 1 + 2 * (usz)n_value) return INVALID_RESULT;
    usz n = (usz)n_value;
    long* x = values + 1;
    long* y = values + 1 + n;
    double rank_x[3], rank_y[3];
    for (usz i = 0; i < n; i++)
        if (x[i] < -1000 || x[i] > 1000 || y[i] < -1000 || y[i] > 1000) return INVALID_RESULT;
    assign_ranks(x, n, &rank_x[0]);
    assign_ranks(y, n, &rank_y[0]);
    double d_squared = 0.0;
    for (usz i = 0; i < n; i++) {
        double difference = rank_x[i] - rank_y[i];
        d_squared += difference * difference;
    }
    double rho = 1.0 - (6.0 * d_squared) / (double)(n * (n * n - 1));
    return round_tenth_ties_even(rho);
}
