module prime_check_naive;

fn long prime_check_naive(long n) @export("prime_check_naive") {
    if (n > 10000) return -1;
    if (n < 2) return 0;
    long divisor = 2;
    while (divisor < n) {
        if (n % divisor == 0) return 0;
        divisor += 1;
    }
    return 1;
}
