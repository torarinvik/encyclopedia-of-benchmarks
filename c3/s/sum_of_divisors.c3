module sum_of_divisors;

// Return the sum of all positive divisors of n by prime factorization.
fn long sum_of_divisors(long n) @export("sum_of_divisors") {
    if (n < 1 || n > 1000000) return -1;
    long remaining = n;
    long sigma = 1;
    for (long factor = 2; factor <= remaining / factor; factor++) {
        if (remaining % factor == 0) {
            long power = 1;
            long geometric_sum = 1;
            while (remaining % factor == 0) {
                remaining /= factor;
                power *= factor;
                geometric_sum += power;
            }
            sigma *= geometric_sum;
        }
    }
    if (remaining > 1) sigma *= remaining + 1;
    return sigma;
}
