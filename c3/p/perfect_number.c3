module perfect_number;

// Check whether n equals the sum of its positive proper divisors.
fn long perfect_number(long n) @export("perfect_number")
{
    if (n <= 1) return 0;
    if (n > 1000000000000) return -1;

    long divisor_sum = 1;
    for (long factor = 2; factor <= n / factor; factor++) {
        if (n % factor == 0) {
            divisor_sum += factor;
            long partner = n / factor;
            if (partner != factor) divisor_sum += partner;
            if (divisor_sum > n) return 0;
        }
    }
    return divisor_sum == n ? 1 : 0;
}
