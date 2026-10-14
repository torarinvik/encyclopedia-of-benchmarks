/* Count primes through limit with the Sieve of Atkin. */
#include <stdint.h>

int64_t sieve_of_atkin(int64_t limit)
{
    if (limit < 0 || limit > 4096) return -1;
    if (limit < 2) return 0;
    uint8_t sieve[4097] = {0};
    for (int64_t x = 1; x <= limit / x; ++x) {
        const int64_t x_squared = x * x;
        for (int64_t y = 1; y <= limit / y; ++y) {
            const int64_t y_squared = y * y;
            int64_t value = 4 * x_squared + y_squared;
            if (value <= limit && (value % 12 == 1 || value % 12 == 5)) sieve[value] ^= 1;
            value = 3 * x_squared + y_squared;
            if (value <= limit && value % 12 == 7) sieve[value] ^= 1;
            if (x > y) {
                value = 3 * x_squared - y_squared;
                if (value <= limit && value % 12 == 11) sieve[value] ^= 1;
            }
        }
    }
    for (int64_t candidate = 5; candidate <= limit / candidate; ++candidate) {
        if (sieve[candidate]) {
            const int64_t square = candidate * candidate;
            for (int64_t multiple = square; multiple <= limit; multiple += square) sieve[multiple] = 0;
        }
    }
    int64_t count = 1 + (limit >= 3);
    for (int64_t value = 5; value <= limit; ++value) count += sieve[value] != 0;
    return count;
}
