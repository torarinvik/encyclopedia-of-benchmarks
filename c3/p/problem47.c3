module problem47;

fn long distinct_prime_factor_count(long value) {
    long count = 0;
    for (long divisor = 2; divisor * divisor <= value; divisor++) {
        if (value % divisor == 0) {
            count++;
            while (value % divisor == 0) value /= divisor;
        }
    }
    if (value > 1) count++;
    return count;
}

fn long problem47(long n) @export("problem47") {
    if (n < 1 || n > 4) return -1;
    long run_length = 0;
    long value = 2;
    while (true) {
        if (distinct_prime_factor_count(value) == n) run_length++;
        else run_length = 0;
        if (run_length == n) return value - n + 1;
        value++;
    }
}
