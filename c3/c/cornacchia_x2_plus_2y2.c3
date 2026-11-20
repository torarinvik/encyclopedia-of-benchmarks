module cornacchia_x2_plus_2y2;

const long CORNACCHIA_MAX_PRIME = 1000000;
const usz CORNACCHIA_MAX_LENGTH = 3;
const long CORNACCHIA_PACK_BASE = 1024;

fn bool cornacchia_is_prime(long value) {
    if (value < 2) return false;
    long divisor = 2;
    while (divisor <= value / divisor) {
        if (value % divisor == 0) return false;
        divisor = divisor == 2 ? 3 : divisor + 2;
    }
    return true;
}

fn long cornacchia_isqrt(long value) {
    long low = 0, high = 1001;
    while (low + 1 < high) {
        long middle = (low + high) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

fn long cornacchia_x2_plus_2y2(long* input, usz length)
        @export("cornacchia_x2_plus_2y2") {
    if (input == null || length < 2 || length > CORNACCHIA_MAX_LENGTH) return -1;
    long prime = input[0], root = input[1];
    if (prime < 3 || prime > CORNACCHIA_MAX_PRIME || (prime & 1) == 0 ||
        root < 1 || root > prime / 2 || length != 2) return -1;
    if (!cornacchia_is_prime(prime) || (root * root + 2) % prime != 0) return -1;

    long previous = prime, current = root;
    long limit = cornacchia_isqrt(prime);
    while (current > limit) {
        long remainder = previous % current;
        previous = current;
        current = remainder;
    }
    long x = current;
    long numerator = prime - x * x;
    if (numerator <= 0 || numerator % 2 != 0) return -1;
    long y_squared = numerator / 2;
    long y = cornacchia_isqrt(y_squared);
    if (y <= 0 || y * y != y_squared || x * x + 2 * y * y != prime) return -1;
    return x * CORNACCHIA_PACK_BASE + y;
}
