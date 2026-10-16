module problem27;

fn bool problem27_is_prime(long value) {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    if (value % 3 == 0) return value == 3;
    for (long factor = 5; factor <= value / factor; factor += 6) {
        if (value % factor == 0 || value % (factor + 2) == 0) return false;
    }
    return true;
}

fn long problem27(long limit) @export("problem27") {
    if (limit < 1 || limit > 1000) return -1;
    long best_length = 0;
    long best_a = 0;
    long best_b = 0;
    for (long a = 1 - limit; a < limit; a++) {
        for (long b = 2; b < limit; b++) {
            if (!problem27_is_prime(b)) continue;
            long n = 0;
            while (problem27_is_prime(n * n + a * n + b)) n++;
            if (n > best_length) {
                best_length = n;
                best_a = a;
                best_b = b;
            }
        }
    }
    return best_a * best_b;
}
