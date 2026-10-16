module peak_signal_to_noise_ratio;

extern fn double sqrt(double value);
extern fn double log10(double value);

fn double peak_signal_to_noise_ratio(long* v, ulong n) @export("peak_signal_to_noise_ratio") {
    if (v == null || n < 3 || n > 129 || v[0] < 1 || v[0] > 64 || n != 1 + 2 * (ulong)v[0]) return -1e300;
    ulong count = (ulong)v[0];
    double sum = 0.0;
    for (ulong i = 0; i < count; i++) {
        long a = v[i + 1], b = v[i + 1 + count];
        if (a < 0 || a > 255 || b < 0 || b > 255) return -1e300;
        if (a - b < -15 || a - b > 15) return -1e300;
        double d = (double)a - (double)b; sum += d * d;
    }
    double mse = sum / (double)count;
    if (mse == 0.0) return -1e300;
    return 20.0 * log10(255.0 / sqrt(mse));
}
