module problem37;

fn bool is_prime(long value) {
    if (value < 2) return false;
    if (value == 2 || value == 3) return true;
    if (value % 2 == 0 || value % 3 == 0) return false;
    for (long divisor = 5; divisor <= value / divisor; divisor += 6) {
        if (value % divisor == 0 || value % (divisor + 2) == 0) return false;
    }
    return true;
}

fn bool is_truncatable_prime(long value) {
    if (!is_prime(value)) return false;
    for (long power = 10; power < value; power *= 10) {
        if (!is_prime(value / power) || !is_prime(value % power)) return false;
    }
    return true;
}

fn long problem37(long ignored) @export("problem37") {
    if (ignored != 0) return -1;
    long found = 0;
    long sum = 0;
    for (long candidate = 13; candidate <= 1000000 && found < 11; candidate += 2) {
        if (is_truncatable_prime(candidate)) {
            sum += candidate;
            found++;
        }
    }
    return found == 11 ? sum : -1;
}
