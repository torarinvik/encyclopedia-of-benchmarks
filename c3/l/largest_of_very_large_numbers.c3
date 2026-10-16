module largest_of_very_large_numbers;

extern fn double log10(double value);
const long MAX_VALUE = 1000000000000L;

fn double source_score(long base, long exponent) {
    if (base == 0) return 0.0;
    if (exponent == 0) return 1.0;
    return (double)exponent * log10((double)base);
}

fn bool valid_comparison_domain(long base_a, long exponent_a, long base_b, long exponent_b) {
    return exponent_a == exponent_b ||
        (base_a == base_b && (base_a == 0 || ((exponent_a == 0) == (exponent_b == 0))));
}

fn long largest_of_very_large_numbers(long* values, usz length) @export("largest_of_very_large_numbers") {
    if (values == null || length != 4) return -2;
    for (usz i = 0; i < 4; i++) if (values[i] < 0 || values[i] > MAX_VALUE) return -2;
    if (!valid_comparison_domain(values[0], values[1], values[2], values[3])) return -2;
    double a = source_score(values[0], values[1]);
    double b = source_score(values[2], values[3]);
    if (a > b) return 1;
    if (a < b) return -1;
    return 0;
}
