/* Count primes through limit with Sundaram's index sieve. */
#include <stdint.h>

int64_t sieve_of_sundaram(int64_t limit)
{
    if (limit < 0 || limit > 4096) return -1;
    if (limit < 2) return 0;

    const int64_t max_index = (limit - 1) / 2;
    uint8_t composite[2048] = {0};
    for (int64_t i = 1; 2 * i * (i + 1) <= max_index; ++i) {
        for (int64_t j = i; ; ++j) {
            const int64_t index = i + j + 2 * i * j;
            if (index > max_index) break;
            composite[index] = 1;
        }
    }

    int64_t count = 1; /* prime 2 */
    for (int64_t index = 1; index <= max_index; ++index)
        count += composite[index] == 0;
    return count;
}
