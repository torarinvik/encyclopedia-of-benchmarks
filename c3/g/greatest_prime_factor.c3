module greatest_prime_factor;

fn bool is_prime_trial(long value)
{
    if (value < 2) return false;
    for (long divisor = 2; divisor <= value / divisor; divisor++) {
        if (value % divisor == 0) return false;
    }
    return true;
}

// Greatest prime factor over the bounded primelib input domain.
fn long greatest_prime_factor(long n) @export("greatest_prime_factor")
{
    if (n < 0 || n > 1000000) return -1;
    if (n < 2) return n;
    if (is_prime_trial(n)) return n;

    long quotient = n;
    long largest = 0;
    long factor = 2;
    while (quotient != 1) {
        if (is_prime_trial(factor) && quotient % factor == 0) {
            largest = factor;
            quotient = quotient / factor;
        } else {
            factor++;
        }
    }
    return largest;
}
