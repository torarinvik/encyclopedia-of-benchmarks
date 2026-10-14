/* Count primes through limit with the Sieve of Atkin. */
#include <cstdint>

extern "C" std::int64_t sieve_of_atkin(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > 4096) return -1;
    if (limit < 2) return 0;
    bool sieve[4097]{};
    for (std::int64_t x = 1; x <= limit / x; ++x) {
        const std::int64_t x_squared = x * x;
        for (std::int64_t y = 1; y <= limit / y; ++y) {
            const std::int64_t y_squared = y * y;
            std::int64_t value = 4 * x_squared + y_squared;
            if (value <= limit && (value % 12 == 1 || value % 12 == 5)) sieve[value] = !sieve[value];
            value = 3 * x_squared + y_squared;
            if (value <= limit && value % 12 == 7) sieve[value] = !sieve[value];
            if (x > y) {
                value = 3 * x_squared - y_squared;
                if (value <= limit && value % 12 == 11) sieve[value] = !sieve[value];
            }
        }
    }
    for (std::int64_t candidate = 5; candidate <= limit / candidate; ++candidate) {
        if (sieve[candidate]) {
            const std::int64_t square = candidate * candidate;
            for (std::int64_t multiple = square; multiple <= limit; multiple += square) sieve[multiple] = false;
        }
    }
    std::int64_t count = 1 + (limit >= 3);
    for (std::int64_t value = 5; value <= limit; ++value) count += sieve[value];
    return count;
}
