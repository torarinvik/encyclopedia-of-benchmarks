module geometric_dist;

const double INVALID_RESULT = -1.0e300;
extern fn double pow(double base, double exponent);
extern fn double sqrt(double value);
extern fn double log(double value);

fn float geometric_cdf(float p, long k) {
    float power = (float)pow((double)(1.0f - p), (double)k);
    return 1.0f - power;
}

// Deterministic operations of the source's first-success geometric distribution.
fn double geometric_dist(long* values, usz length) @export("geometric_dist") {
    if (values == null || length < 2) return INVALID_RESULT;
    long operation = values[0];
    long p_code = values[1];
    if (p_code < 0 || p_code > 2) return INVALID_RESULT;
    float probabilities[3] = {0.25f, 0.5f, 0.75f};
    float p = probabilities[(usz)p_code];
    if (operation >= 0 && operation <= 2) {
        if (length != 2) return INVALID_RESULT;
        if (operation == 0) return (double)(1.0f / p);
        float variance = (1.0f - p) / (p * p);
        return (double)(operation == 1 ? variance : (float)sqrt((double)variance));
    }
    if (operation == 3 || operation == 4) {
        if (length != 3) return INVALID_RESULT;
        long k = values[2];
        if (operation == 3 && (k < 1 || k > 16)) return INVALID_RESULT;
        if (operation == 4 && (k < 0 || k > 16)) return INVALID_RESULT;
        if (operation == 3) {
            float power = (float)pow((double)(1.0f - p), (double)(k - 1));
            return (double)(power * p);
        }
        return (double)geometric_cdf(p, k);
    }
    if (operation == 5) {
        if (length != 3 || values[2] < 0 || values[2] > 2) return INVALID_RESULT;
        float cdf_values[3] = {0.25f, 0.5f, 0.75f};
        float cdf = cdf_values[(usz)values[2]];
        float numerator = (float)log((double)(1.0f - cdf));
        float denominator = (float)log((double)(1.0f - p));
        return (double)(numerator / denominator);
    }
    if (operation == 6) {
        if (length != 4) return INVALID_RESULT;
        long minimum = values[2];
        long maximum = values[3];
        if (minimum < 1 || maximum < minimum || maximum > 16) return INVALID_RESULT;
        float lower = geometric_cdf(p, minimum - 1);
        float upper = geometric_cdf(p, maximum);
        return (double)(upper - lower);
    }
    return INVALID_RESULT;
}
