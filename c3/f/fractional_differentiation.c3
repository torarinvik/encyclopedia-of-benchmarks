module fractional_differentiation;
const usz MAX_WINDOW = 8;
const usz MAX_SERIES = 16;
fn double fractional_differentiation(long* values, usz length) @export("fractional_differentiation") {
    if (values == null || length < 4 || length > 18) return -1.0e300;
    long d_units = values[0];
    long wv = values[1];
    usz n = length - 2;
    if (d_units < 0 || d_units > 1000000 || wv < 1 || wv > (long)MAX_WINDOW || n <= (usz)wv || n > MAX_SERIES) return -1.0e300;
    for (usz i = 0; i < n; i++) if (values[2+i] < -1000000 || values[2+i] > 1000000) return -1.0e300;
    double d = (double)d_units / 1000000.0;
    double[MAX_WINDOW] weights = {}; weights[0] = 1.0;
    for (usz k = 1; k < (usz)wv; k++) weights[k] = -weights[k-1] * (d - (double)k + 1.0) / (double)k;
    double result = 0.0;
    for (usz j = 0; j < (usz)wv; j++) result += weights[j] * ((double)values[2+n-1-j] / 1000.0);
    return result;
}
