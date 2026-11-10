module perfect_number;

// Check whether n equals the sum of its positive proper divisors.
fn long perfect_number(long n) @export("perfect_number")
{
    if (n <= 1) return 0;
    if (n > 1000000000000) return -1;

    ulong number = (ulong)n;
    ulong stride = 1 + (number & 1);
    ulong divisor_sum = 1;
    if (stride == 1 && number >= 4) {
        ulong half = number >> 1;
        divisor_sum = half == 2 ? 3 : 3 + half;
    }
    for (ulong factor = 3; ; factor += stride) {
        ulong partner = number / factor;
        if (factor > partner) break;
        if (partner * factor == number) {
            divisor_sum += factor;
            if (partner != factor) divisor_sum += partner;
            if (divisor_sum > number) return 0;
        }
    }
    return divisor_sum == number ? 1 : 0;
}
