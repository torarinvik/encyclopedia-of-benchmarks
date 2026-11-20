#include <stddef.h>
#include <stdint.h>

enum { CORNACCHIA_MAX_PRIME = 1000000, CORNACCHIA_MAX_LENGTH = 3,
       CORNACCHIA_PACK_BASE = 1024 };

static int64_t cornacchia_is_prime(int64_t value) {
    if (value < 2) return 0;
    int64_t divisor = 2;
    while (divisor <= value / divisor) {
        if (value % divisor == 0) return 0;
        divisor = divisor == 2 ? 3 : divisor + 2;
    }
    return 1;
}

static int64_t cornacchia_isqrt(int64_t value) {
    int64_t low = 0, high = 1001;
    while (low + 1 < high) {
        const int64_t middle = (low + high) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

int64_t cornacchia_x2_plus_2y2(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > CORNACCHIA_MAX_LENGTH) return -1;
    const int64_t prime = input[0], root = input[1];
    if (prime < 3 || prime > CORNACCHIA_MAX_PRIME || (prime & 1) == 0 ||
        root < 1 || root > prime / 2 || length != 2) return -1;
    if (!cornacchia_is_prime(prime) || (root * root + 2) % prime != 0) return -1;

    int64_t previous = prime, current = root;
    const int64_t limit = cornacchia_isqrt(prime);
    while (current > limit) {
        const int64_t remainder = previous % current;
        previous = current;
        current = remainder;
    }
    const int64_t x = current;
    const int64_t numerator = prime - x * x;
    if (numerator <= 0 || numerator % 2 != 0) return -1;
    const int64_t y_squared = numerator / 2;
    const int64_t y = cornacchia_isqrt(y_squared);
    if (y <= 0 || y * y != y_squared || x * x + 2 * y * y != prime) return -1;
    return x * CORNACCHIA_PACK_BASE + y;
}
