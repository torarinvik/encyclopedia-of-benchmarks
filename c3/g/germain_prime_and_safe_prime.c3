module germain_prime_and_safe_prime;

const long MAX_NUMBER = 1000000L;

fn bool is_prime(long value) {
    if (value == 2) return true;
    if (value < 2 || value % 2 == 0) return false;
    for (long divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn long germain_prime_and_safe_prime(long* values, usz length) @export("germain_prime_and_safe_prime") {
    if (values == null || length != 2) return -1;
    long number = values[0];
    long selector = values[1];
    if (number < 1 || number > MAX_NUMBER || selector < 0 || selector > 1) return -1;
    if (selector == 0) return is_prime(number) && is_prime(2 * number + 1) ? 1 : 0;
    return ((number - 1) % 2 == 0 && is_prime(number) && is_prime((number - 1) / 2)) ? 1 : 0;
}
