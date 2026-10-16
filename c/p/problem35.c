/* Count circular primes below one million using an odd-only sieve. */
#include <stdbool.h>
#include <stdint.h>

#define MAX_LIMIT INT64_C(1000000)
#define ODD_SLOTS 500001

int64_t problem35(int64_t ignored)
{
    if (ignored != 0) return -1;
    uint8_t odd_prime[ODD_SLOTS] = {0};
    for (int64_t index = 1; index < ODD_SLOTS; ++index) odd_prime[index] = 1;

    for (int64_t candidate = 3; candidate <= MAX_LIMIT / candidate; candidate += 2) {
        if (odd_prime[candidate / 2]) {
            for (int64_t composite = candidate * candidate; composite <= MAX_LIMIT;
                 composite += 2 * candidate) {
                odd_prime[composite / 2] = 0;
            }
        }
    }

    int64_t count = 1; /* The source result starts with prime 2. */
    for (int64_t number = 3; number <= MAX_LIMIT; number += 2) {
        if (!odd_prime[number / 2]) continue;
        int64_t remaining = number;
        bool has_even_digit = false;
        while (remaining > 0) {
            if ((remaining % 10) % 2 == 0) {
                has_even_digit = true;
                break;
            }
            remaining /= 10;
        }
        if (has_even_digit) continue;

        int64_t power10 = 1;
        int64_t digits = 1;
        remaining = number;
        while (remaining >= 10) {
            power10 *= 10;
            remaining /= 10;
            ++digits;
        }
        int64_t rotation = number;
        bool circular = true;
        for (int64_t turn = 0; turn < digits; ++turn) {
            if (!odd_prime[rotation / 2]) {
                circular = false;
                break;
            }
            rotation = (rotation % 10) * power10 + rotation / 10;
        }
        if (circular) ++count;
    }
    return count;
}
