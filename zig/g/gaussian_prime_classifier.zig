const MAX_COORDINATE: i64 = 10_000;

fn rationalPrime(value: i64) bool {
    if (value < 2) return false;
    if (@mod(value, 2) == 0) return value == 2;
    var divisor: i64 = 3;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 2) {
        if (@mod(value, divisor) == 0) return false;
    }
    return true;
}

pub export fn gaussian_prime_classifier(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > 3) return -1;
    if (length != 2) return -1;
    const input = values.?;
    const real = input[0];
    const imaginary = input[1];
    if (real < -MAX_COORDINATE or real > MAX_COORDINATE or
        imaginary < -MAX_COORDINATE or imaginary > MAX_COORDINATE) return -1;
    if (real == 0 and imaginary == 0) return 0;
    if (real == 0 or imaginary == 0) {
        const axis = if (real == 0) imaginary else real;
        const rational = if (axis < 0) -axis else axis;
        return @intFromBool(@mod(rational, 4) == 3 and rationalPrime(rational));
    }
    const norm = real * real + imaginary * imaginary;
    return @intFromBool(rationalPrime(norm));
}
