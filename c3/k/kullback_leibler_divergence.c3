module kullback_leibler_divergence;

extern fn double log(double value);
const long MAX_COUNT = 64;
const double SCALE = 1000000.0;
const double INVALID_RESULT = -1.0e300;

fn double kullback_leibler_divergence(long* values, usz length) @export("kullback_leibler_divergence") {
    if (values == null || length < 3 || length > 129) return INVALID_RESULT;
    long count_value = values[0];
    if (count_value < 1 || count_value > MAX_COUNT) return INVALID_RESULT;
    usz count = (usz)count_value;
    if (length != 1 + 2 * count) return INVALID_RESULT;
    for (usz i = 0; i < count; i++) {
        long target = values[1 + i];
        long prediction = values[1 + count + i];
        if (target < 0 || target > 1000000 || prediction < 0 || prediction > 1000000 ||
            (target > 0 && prediction == 0)) {
            return INVALID_RESULT;
        }
    }
    double total = 0.0;
    for (usz i = 0; i < count; i++) {
        long target_scaled = values[1 + i];
        if (target_scaled == 0) continue;
        long prediction_scaled = values[1 + count + i];
        double target = (double)target_scaled / SCALE;
        double prediction = (double)prediction_scaled / SCALE;
        total += target * log(target / prediction);
    }
    return total;
}
