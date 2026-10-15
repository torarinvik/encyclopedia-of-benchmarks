module euler_totient;

// Euler's totient via distinct-prime factorization.
fn long euler_totient(long n) @export("euler_totient") {
    if (n < 1 || n > 1000000) return -1;
    long result = n;
    long remaining = n;
    for (long factor = 2; factor <= remaining / factor; factor++) {
        if (remaining % factor == 0) {
            while (remaining % factor == 0) remaining /= factor;
            result -= result / factor;
        }
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}
