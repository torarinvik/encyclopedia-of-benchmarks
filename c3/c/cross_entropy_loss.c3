module cross_entropy_loss;

extern fn double log(double value);
const long MAX_COUNT = 64;
const double SCALE = 1000000.0;
const double INVALID_RESULT = -1.0e300;

fn double cross_entropy_loss(long* values, usz length) @export("cross_entropy_loss") {
    if (values == null || length < 1) return INVALID_RESULT;
    long count = values[0];
    if (count < 1 || count > MAX_COUNT || length != 1 + 2 * (usz)count) return INVALID_RESULT;
    double[MAX_COUNT] terms;
    for (usz i = 0; i < (usz)count; i++) {
        long actual_scaled = values[1 + i];
        long predicted_scaled = values[1 + (usz)count + i];
        if (actual_scaled < 0 || actual_scaled > 1000000 || predicted_scaled < 1 || predicted_scaled > 1000000)
            return INVALID_RESULT;
        double actual = (double)actual_scaled / SCALE;
        double predicted = (double)predicted_scaled / SCALE;
        terms[i] = -actual * log(predicted);
    }
    double total = 0.0;
    for (usz i = 0; i < (usz)count; i++) total += terms[i];
    return total;
}
