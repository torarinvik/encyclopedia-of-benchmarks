module smallest_prime_factor;

const long MAX_N = 1000005L;

fn long smallest_prime_factor(long* input, usz length) @export("smallest_prime_factor") {
    if (input == null || length != 1) return -1L;
    long n = input[0];
    if (n < 2L || n > MAX_N) return -1L;
    long factor = 2L;
    while (factor <= n / factor) {
        if (n % factor == 0L) return factor;
        factor += 1L;
    }
    return n;
}
