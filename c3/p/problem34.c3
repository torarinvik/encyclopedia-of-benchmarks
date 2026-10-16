module problem34;

const long[10] DIGIT_FACTORIALS = {1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880};

fn long digit_factorial(long digit) {
    return DIGIT_FACTORIALS[(usz)digit];
}

fn long problem34(long ignored) @export("problem34") {
    if (ignored != 0) return -1;
    long total = 0;
    for (long number = 3; number <= 2540160; number++) {
        long remaining = number;
        long digit_sum = 0;
        while (remaining > 0) {
            digit_sum += digit_factorial(remaining % 10);
            remaining /= 10;
        }
        if (digit_sum == number) total += number;
    }
    return total;
}
