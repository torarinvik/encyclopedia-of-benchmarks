module is_square_free;

// Return whether positive n has no repeated prime factor.
fn long is_square_free(long n) @export("is_square_free")
{
    if (n < 1 || n > 1000000) return -1;
    for (long factor = 2; factor <= n / factor; factor++) {
        if (n % factor == 0) {
            n /= factor;
            if (n % factor == 0) return 0;
        }
    }
    return 1;
}
