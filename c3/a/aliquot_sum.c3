module aliquot_sum;

// Scan proper divisors under the shared signed 64-bit contract.
fn long aliquot_sum(long n) @export("aliquot_sum")
{
    if (n < 0) return -1;
    long sum = 0;
    for (long divisor = 1; divisor <= n / 2; divisor++) {
        if (n % divisor == 0) {
            if (sum > 9223372036854775807 - divisor) return -1;
            sum += divisor;
        }
    }
    return sum;
}
