/// Sum LCM(i, n), 1 <= i <= n, using the Euler-totient identity.
fn euler_phi(value: u64) u64 {
    var result = value;
    var remaining = value;
    var factor: u64 = 2;
    while (factor <= remaining / factor) {
        if (remaining % factor == 0) {
            result -= result / factor;
            while (remaining % factor == 0) remaining /= factor;
        }
        if (factor == 2) factor = 3 else factor += 2;
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}

export fn lcm_sum(input: i64) i64 {
    if (input < 1 or input > 65535) return -1;
    const n: u64 = @intCast(input);
    var weighted_totients: u64 = 1;
    var divisor: u64 = 1;
    while (divisor <= n / divisor) : (divisor += 1) {
        if (n % divisor == 0) {
            weighted_totients += divisor * euler_phi(divisor);
            const paired = n / divisor;
            if (paired != divisor) weighted_totients += paired * euler_phi(paired);
        }
    }
    return @intCast((weighted_totients * n) / 2);
}
