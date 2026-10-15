const MAX_NUMBER: i64 = 1_000_000;

fn isPrime(value: i64) bool {
    if (value == 2) return true;
    if (value < 2 or @mod(value, 2) == 0) return false;
    var divisor: i64 = 3;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 2) {
        if (@mod(value, divisor) == 0) return false;
    }
    return true;
}

export fn germain_prime_and_safe_prime(values: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const number = values[0];
    const selector = values[1];
    if (number < 1 or number > MAX_NUMBER or selector < 0 or selector > 1) return -1;
    if (selector == 0) {
        return if (isPrime(number) and isPrime(2 * number + 1)) 1 else 0;
    }
    return if (@mod(number - 1, 2) == 0 and isPrime(number) and isPrime(@divTrunc(number - 1, 2))) 1 else 0;
}
