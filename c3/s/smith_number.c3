module smith_number;

fn bool is_prime(long value) {
    if (value == 2) return true;
    if (value < 2 || value % 2 == 0) return false;
    for (long divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn long digit_sum(long value) {
    long sum = 0;
    while (value != 0) {
        sum += value % 10;
        value /= 10;
    }
    return sum;
}

fn long prime_factor_digit_sum(long value) {
    long sum = 0;
    long remainder = value;
    for (long factor = 2; factor <= value / factor; factor++) {
        while (remainder % factor == 0) {
            sum += digit_sum(factor);
            remainder /= factor;
        }
    }
    if (remainder > 1) sum += digit_sum(remainder);
    return sum;
}

fn long smith_number(long value) @export("smith_number") {
    if (value < 1 || value > 2147395599) return -1;
    if (is_prime(value)) return 0;
    return digit_sum(value) == prime_factor_digit_sum(value) ? 1 : 0;
}
