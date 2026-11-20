const MAX_PRIME: i64 = 100_000;

fn isPrime(value: i64) bool {
    if (value < 2) return false;
    if (@mod(value, 2) == 0) return value == 2;
    var divisor: i64 = 3;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 2) {
        if (@mod(value, divisor) == 0) return false;
    }
    return true;
}

fn classForPrime(prime: i64, direction: i64) i64 {
    var remainder = prime + direction;
    var best: i64 = 1;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(remainder, divisor)) : (divisor += 1) {
        if (@mod(remainder, divisor) == 0) {
            if (divisor > 3) {
                const candidate = 1 + classForPrime(divisor, direction);
                if (candidate > best) best = candidate;
            }
            while (@mod(remainder, divisor) == 0) {
                remainder = @divTrunc(remainder, divisor);
            }
        }
    }
    if (remainder > 3) {
        const candidate = 1 + classForPrime(remainder, direction);
        if (candidate > best) best = candidate;
    }
    return best;
}

pub export fn erdos_selfridge_prime_class(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > 3) return -1;
    if (length != 2) return -1;
    const input = values.?;
    const prime = input[0];
    const direction = input[1];
    if (prime < 2 or prime > MAX_PRIME or (direction != -1 and direction != 1)) return -1;
    if (!isPrime(prime)) return -1;
    return classForPrime(prime, direction);
}

