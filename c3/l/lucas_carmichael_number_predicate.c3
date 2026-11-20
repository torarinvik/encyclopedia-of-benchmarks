module lucas_carmichael_number_predicate;

fn long lucas_carmichael_number_predicate(long* input, usz length) @export("lucas_carmichael_number_predicate") {
    if (input == null || length != 1) return -1;
    long value = input[0];
    if (value < 1 || value > 1000000) return -1;

    long remaining = value;
    long divisor = 2;
    bool found_factor = false;
    while (divisor <= remaining / divisor) {
        if (remaining % divisor == 0) {
            found_factor = true;
            long exponent = 0;
            do {
                remaining /= divisor;
                exponent += 1;
            } while (remaining % divisor == 0);
            if (exponent != 1 || (value + 1) % (divisor + 1) != 0) return 0;
        }
        divisor += 1;
    }
    if (remaining > 1) {
        if (!found_factor) return 0;
        if ((value + 1) % (remaining + 1) != 0) return 0;
    }
    if (found_factor) return 1;
    return 0;
}
