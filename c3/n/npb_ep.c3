module npb_ep;

extern fn double trunc(double value);
extern fn double sqrt(double value);
extern fn double log(double value);
extern fn double fabs(double value);

const usz MAX_PAIRS = 4096;
const usz HISTOGRAM_BINS = 10;
const long MODULUS_MASK = 70368744177663;
const long WORD_MASK = 8388607;
const long MULTIPLIER = 1220703125;
const double MODULUS_SCALE = 70368744177664.0;

fn bool is_bounded_integer(double value, double minimum, double maximum) {
    return value == value && trunc(value) == value && value >= minimum && value <= maximum;
}

fn long advance_state(long state) {
    long low = state & WORD_MASK;
    long high = state >> 23;
    long multiplier_low = MULTIPLIER & WORD_MASK;
    long multiplier_high = MULTIPLIER >> 23;
    long low_product = low * multiplier_low;
    long cross = (low * multiplier_high + high * multiplier_low) & WORD_MASK;
    return (low_product + (cross << 23)) & MODULUS_MASK;
}

fn long npb_ep(double* input, usz length, double* output, usz capacity)
    @export("npb_ep") {
    if (input == null || length != 2 ||
        !is_bounded_integer(input[0], 1.0, (double)MAX_PAIRS) ||
        !is_bounded_integer(input[1], 1.0, 70368744177663.0)) return -1;
    usz pair_count = (usz)input[0];
    if (output == null || capacity < 12) return -2;

    long state = (long)input[1];
    long histogram[10] = {0};
    double sum_x = 0.0, sum_y = 0.0;
    for (usz pair = 0; pair < pair_count; pair += 1) {
        state = advance_state(state);
        double x = 2.0 * ((double)state / MODULUS_SCALE) - 1.0;
        state = advance_state(state);
        double y = 2.0 * ((double)state / MODULUS_SCALE) - 1.0;
        double radius_squared = x * x + y * y;
        if (radius_squared <= 0.0 || radius_squared > 1.0) continue;
        double scale = sqrt(-2.0 * log(radius_squared) / radius_squared);
        double normal_x = x * scale, normal_y = y * scale;
        double extent_x = fabs(normal_x), extent_y = fabs(normal_y);
        double extent = extent_x > extent_y ? extent_x : extent_y;
        if (extent < 10.0) histogram[(usz)extent] += 1;
        sum_x += normal_x;
        sum_y += normal_y;
    }
    for (usz bin = 0; bin < HISTOGRAM_BINS; bin += 1) output[bin] = (double)histogram[bin];
    output[10] = sum_x;
    output[11] = sum_y;
    return 12;
}
