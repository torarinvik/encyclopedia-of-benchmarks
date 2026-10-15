module rainfall_intensity;

extern fn double pow(double base, double exponent);
const double INVALID_RESULT = -1.0e300;

fn double rainfall_intensity(long* values, usz length) @export("rainfall_intensity") {
    if (values == null || length != 6) return INVALID_RESULT;
    long k = values[0];
    long a = values[1];
    long b = values[2];
    long c = values[3];
    long period = values[4];
    long duration = values[5];
    if (k < 1 || k > 1000 || a < 1 || a > 3 || b < 1 || b > 100 || c < 1 || c > 3 ||
        period < 1 || period > 100 || duration < 1 || duration > 1000) return INVALID_RESULT;
    return ((double)k * pow((double)period, (double)a)) / pow((double)(duration + b), (double)c);
}
