module kth_root_integer;

fn bool power_at_most(long base, long exponent, long limit) {
    if (base == 0) return true;
    long product = 1;
    while (exponent > 0) {
        if (product > limit / base) return false;
        product *= base;
        exponent -= 1;
    }
    return true;
}

fn long kth_root_integer(long* input, usz length) @export("kth_root_integer") {
    if (input == null || length != 2) return -1;
    long number = input[0];
    long degree = input[1];
    if (number < 0 || degree < 1 || degree > 64) return -1;

    long low = 0;
    long high = number;
    while (low < high) {
        long difference = high - low;
        long candidate = low + difference / 2 + difference % 2;
        if (power_at_most(candidate, degree, number)) low = candidate;
        else high = candidate - 1;
    }
    return low;
}
