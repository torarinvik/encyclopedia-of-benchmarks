module problem99;

extern fn double log10(double value);
const usz MAX_PAIR_COUNT = 1000;
const long MAX_BASE = 1000000;
const long MAX_EXPONENT = 1200000;

fn long problem99(long* input, usz length) @export("problem99") {
    if (input == null || length < 1) return -1;
    long pair_count_value = input[0];
    if (pair_count_value < 0 || pair_count_value > MAX_PAIR_COUNT.long()) return -1;
    usz pair_count = (usz)pair_count_value;
    if (length != 1 + 2 * pair_count) return -1;

    double largest = 0.0;
    long result = 0;
    for (usz index = 0; index < pair_count; index++) {
        long base = input[1 + 2 * index];
        long exponent = input[2 + 2 * index];
        if (base < 1 || base > MAX_BASE || exponent < 0 || exponent > MAX_EXPONENT) return -1;
        double value = exponent.double() * log10(base.double());
        if (value > largest) {
            largest = value;
            result = index.long() + 1;
        }
    }
    return result;
}
