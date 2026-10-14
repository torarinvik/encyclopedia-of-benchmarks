module lcm_sum;

fn ulong euler_phi(ulong value)
{
    ulong result = value;
    ulong remaining = value;
    ulong factor = 2;
    while (factor <= remaining / factor) {
        if (remaining % factor == 0) {
            result -= result / factor;
            while (remaining % factor == 0) remaining /= factor;
        }
        if (factor == 2) {
            factor = 3;
        } else {
            factor += 2;
        }
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}

// Sum LCM(i, n), 1 <= i <= n, using the Euler-totient identity.
fn long lcm_sum(long input) @export("lcm_sum")
{
    if (input < 1 || input > 65535) return -1;
    ulong n = (ulong)input;
    ulong weighted_totients = 1;
    ulong divisor = 1;
    while (divisor <= n / divisor) {
        if (n % divisor == 0) {
            weighted_totients += divisor * euler_phi(divisor);
            ulong paired = n / divisor;
            if (paired != divisor) weighted_totients += paired * euler_phi(paired);
        }
        divisor++;
    }
    return (long)((weighted_totients * n) / 2);
}
