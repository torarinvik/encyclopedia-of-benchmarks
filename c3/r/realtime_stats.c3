module realtime_stats;

const double INVALID_RESULT = -1.0e300;
const usz MAX_INPUT_LENGTH = 36;
const long MAX_SAMPLES = 32;
extern fn float sqrtf(float value);
extern fn double sqrt(double value);

fn double realtime_stats(long* values, usz length) @export("realtime_stats") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long variant = values[0], statistic = values[1], count = values[2];
    if (variant < 0 || variant > 2 || statistic < 0 || statistic > 2 ||
        count < 2 || count > MAX_SAMPLES || length != (usz)(3 + count)) return INVALID_RESULT;
    for (usz i = 0; i < (usz)count; i++)
        if (values[3 + i] < -64 || values[3 + i] > 64) return INVALID_RESULT;

    float mean32 = 0.0f, variance32 = 0.0f;
    double mean64 = 0.0, variance64 = 0.0;
    if (variant == 0) {
        float anchor = 0.0f, ex = 0.0f, ex2 = 0.0f;
        uint n = 0;
        for (usz i = 0; i < (usz)count; i++) {
            float x = (float)values[3 + i] / 16.0f;
            if (n == 0) anchor = x;
            n++;
            float tmp = x - anchor;
            ex += tmp;
            ex2 += tmp * tmp;
        }
        mean32 = anchor + ex / (float)n;
        variance32 = (ex2 - (ex * ex) / (float)n) / (float)(n - 1);
    } else if (variant == 1) {
        float mu = 0.0f, m = 0.0f;
        uint n = 0;
        for (usz i = 0; i < (usz)count; i++) {
            float x = (float)values[3 + i] / 16.0f;
            n++;
            float delta = x - mu;
            mu += delta / (float)n;
            float delta2 = x - mu;
            m += delta * delta2;
        }
        mean32 = mu;
        variance32 = m / (float)n;
    } else {
        double mu = 0.0, m = 0.0;
        uint n = 0;
        for (usz i = 0; i < (usz)count; i++) {
            float x32 = (float)values[3 + i] / 16.0f;
            double x = (double)x32;
            n++;
            double delta = x - mu;
            mu += delta / (double)n;
            double delta2 = x - mu;
            m += delta * delta2;
        }
        mean64 = mu;
        variance64 = m / (double)n;
    }

    if (variant < 2) {
        if (statistic == 0) return (double)mean32;
        if (statistic == 1) return (double)variance32;
        return (double)sqrtf(variance32);
    }
    if (statistic == 0) return mean64;
    if (statistic == 1) return variance64;
    return sqrt(variance64);
}
