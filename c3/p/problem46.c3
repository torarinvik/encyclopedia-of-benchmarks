module problem46;

const long MAX_ODD_COMPOSITE = 99999;

fn bool is_prime(long number) {
    if (number < 2) return false;
    if (number < 4) return true;
    if (number % 2 == 0 || number % 3 == 0) return false;
    for (long divisor = 5; divisor <= number / divisor; divisor += 6) {
        if (number % divisor == 0 || number % (divisor + 2) == 0) return false;
    }
    return true;
}

fn long find_first_counterexample() {
    for (long candidate = 3; candidate <= MAX_ODD_COMPOSITE; candidate += 2) {
        if (is_prime(candidate)) continue;
        bool represented = false;
        for (long square = 0; 2 * square * square <= candidate; square++) {
            if (is_prime(candidate - 2 * square * square)) {
                represented = true;
                break;
            }
        }
        if (!represented) return candidate;
    }
    return -1;
}

fn long problem46(long placeholder) @export("problem46") {
    if (placeholder != 0) return -1;
    return find_first_counterexample();
}
