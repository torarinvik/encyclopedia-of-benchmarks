module problem30;

fn long digit_fifth_power(long digit) {
    return digit * digit * digit * digit * digit;
}

fn long problem30(long ignored) @export("problem30") {
    if (ignored != 0) return -1;
    long total = 0;
    for (long number = 1000; number < 1000000; number++) {
        long remaining = number;
        long digit_sum = 0;
        while (remaining > 0) {
            digit_sum += digit_fifth_power(remaining % 10);
            remaining /= 10;
        }
        if (digit_sum == number) total += number;
    }
    return total;
}
