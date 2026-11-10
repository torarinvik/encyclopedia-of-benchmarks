/// Check whether n equals the sum of its positive proper divisors.
export fn perfect_number(n: i64) i64 {
    if (n <= 1) return 0;
    if (n > 1000000000000) return -1;

    const number: u64 = @intCast(n);
    const stride = 1 + (number & 1);
    var divisor_sum: u64 = 1;
    if (stride == 1 and number >= 4) {
        const half = number >> 1;
        divisor_sum = if (half == 2) 3 else 3 + half;
    }
    var factor: u64 = 3;
    while (true) : (factor += stride) {
        const partner = number / factor;
        if (factor > partner) break;
        if (partner * factor == number) {
            divisor_sum += factor;
            if (partner != factor) divisor_sum += partner;
            if (divisor_sum > number) return 0;
        }
    }
    return if (divisor_sum == number) 1 else 0;
}
