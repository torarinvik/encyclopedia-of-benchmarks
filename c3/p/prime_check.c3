module prime_check;

// Trial-division primality check over the shared bounded integer domain.
fn long prime_check(long n) @export("prime_check")
{
    if (n < 2) return 0;
    if (n > 2147483647) return -1;
    if (n % 2 == 0) return n == 2 ? 1 : 0;
    for (long factor = 3; factor <= n / factor; factor += 2) {
        if (n % factor == 0) return 0;
    }
    return 1;
}
