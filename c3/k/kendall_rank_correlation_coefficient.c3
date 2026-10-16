module kendall_tau_b;

extern fn double sqrt(double value);
const double INVALID_RESULT = -1.0e300;

fn double kendall_rank_correlation_coefficient(long* values, usz length) @export("kendall_rank_correlation_coefficient") {
    if (values == null || length < 5 || length > 257) return INVALID_RESULT;
    long count = values[0];
    if (count < 2 || count > 128 || length != 1 + 2 * (usz)count) return INVALID_RESULT;
    for (usz i = 0; i < 2 * (usz)count; i++) {
        if (values[1 + i] < -1000000 || values[1 + i] > 1000000) return INVALID_RESULT;
    }

    long concordant = 0;
    long discordant = 0;
    long ties_x = 0;
    long ties_y = 0;
    usz n = (usz)count;
    for (usz i = 0; i < n; i++) {
        for (usz j = i + 1; j < n; j++) {
            long x1 = values[1 + i];
            long x2 = values[1 + j];
            long y1 = values[1 + n + i];
            long y2 = values[1 + n + j];
            if (x1 == x2) ties_x++;
            if (y1 == y2) ties_y++;
            if ((x1 < x2 && y1 < y2) || (x1 > x2 && y1 > y2)) { concordant++; }
            else if ((x1 < x2 && y1 > y2) || (x1 > x2 && y1 < y2)) { discordant++; }
        }
    }
    double pairs = (double)(n * (n - 1) / 2);
    double denominator = sqrt((pairs - (double)ties_x) * (pairs - (double)ties_y));
    if (denominator == 0.0) return INVALID_RESULT;
    return (double)(concordant - discordant) / denominator;
}
