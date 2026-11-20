const max_prime: i64 = 1_000_000;
const pack_base: i64 = 1024;

fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor = if (divisor == 2) 3 else divisor + 2) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn isqrt(value: i64) i64 {
    var low: i64 = 0;
    var high: i64 = 1001;
    while (low + 1 < high) {
        const middle = @divTrunc(low + high, 2);
        if (middle * middle <= value) low = middle else high = middle;
    }
    return low;
}

export fn cornacchia_x2_plus_2y2(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const words = input.?;
    const prime = words[0];
    const root = words[1];
    if (prime < 3 or prime > max_prime or @rem(prime, 2) == 0 or root < 1 or root > @divTrunc(prime, 2)) return -1;
    if (!isPrime(prime) or @rem(root * root + 2, prime) != 0) return -1;

    var previous = prime;
    var current = root;
    const limit = isqrt(prime);
    while (current > limit) {
        const remainder = @rem(previous, current);
        previous = current;
        current = remainder;
    }
    const x = current;
    const numerator = prime - x * x;
    if (numerator <= 0 or @rem(numerator, 2) != 0) return -1;
    const y_squared = @divTrunc(numerator, 2);
    const y = isqrt(y_squared);
    if (y <= 0 or y * y != y_squared or x * x + 2 * y * y != prime) return -1;
    return x * pack_base + y;
}
