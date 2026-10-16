module neville;

const double INVALID_RESULT = -1.0e300;

fn double neville(long* values, usz length) @export("neville") {
    if (values == null || length < 4 || length > 34) return INVALID_RESULT;
    long count = values[0], target_i = values[1];
    if (count < 1 || count > 16 || length != (usz)(2 * count + 2) || target_i < -1000000 || target_i > 1000000) return INVALID_RESULT;
    double x[16], p[16];
    for (usz i = 0; i < (usz)count; i++) {
        long xi = values[2 + 2 * i], yi = values[3 + 2 * i];
        if (xi < -1000000 || xi > 1000000 || yi < -1000000 || yi > 1000000) return INVALID_RESULT;
        for (usz j = 0; j < i; j++) if (values[2 + 2 * j] == xi) return INVALID_RESULT;
        x[i] = (double)xi; p[i] = (double)yi;
    }
    double target = (double)target_i;
    for (long k = 1; k < count; k++)
        for (long i = 0; i < count - k; i++)
            p[i] = ((target - x[i + k]) * p[i] + (x[i] - target) * p[i + 1]) / (x[i] - x[i + k]);
    return p[0];
}
