module mersenne_prime;

fn bool is_prime_i64(long n) {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    long factor = 3;
    while (factor <= n / factor) : (factor += 2) {
        if (n % factor == 0) return false;
    }
    return true;
}

fn long mersenne_prime(long n) @export("mersenne_prime")
{
    if (n == 0) return 0;
    if (n < 0 || n > 2147483647) return -1;
    long remaining = n + 1;
    while (remaining % 2 == 0) remaining /= 2;
    if (remaining != 1) return 0;
    return is_prime_i64(n) ? 1 : 0;
}
