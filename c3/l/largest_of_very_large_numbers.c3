module largest_of_very_large_numbers;

const long MAX_VALUE = 1000000000000L;

fn long decimal_exponent(long base) {
    if (base < 1) return -1;
    long exponent = 0;
    while (base > 1 && base % 10 == 0) {
        base /= 10;
        exponent++;
    }
    return base == 1 ? exponent : -1;
}

fn bool valid_base(long base) {
    return base == 0 || decimal_exponent(base) >= 0;
}

fn long source_score(long base, long exponent) {
    if (base == 0) return 0;
    if (exponent == 0) return 1;
    return decimal_exponent(base) * exponent;
}

fn long largest_of_very_large_numbers(long* values, usz length) @export("largest_of_very_large_numbers") {
    if (values == null || length != 4) return -2;
    for (usz i = 0; i < 4; i++) if (values[i] < 0 || values[i] > MAX_VALUE) return -2;
    if (!valid_base(values[0]) || !valid_base(values[2])) return -2;
    long a = source_score(values[0], values[1]);
    long b = source_score(values[2], values[3]);
    if (a > b) return 1;
    if (a < b) return -1;
    return 0;
}
