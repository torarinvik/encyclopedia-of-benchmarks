/* Generate zero-based prime terms using divisibility by all earlier primes. */
#include <stdint.h>

int64_t primes_sequence(int64_t index)
{
    if (index < 0 || index > 99) return -1;
    int64_t primes[100] = {2};
    int64_t count = 1;
    int64_t candidate = 3;
    while (count <= index) {
        int64_t is_prime = 1;
        for (int64_t i = 0; i < count; ++i) {
            if (candidate % primes[i] == 0) {
                is_prime = 0;
                break;
            }
        }
        if (is_prime) primes[count++] = candidate;
        candidate += 2;
    }
    return primes[index];
}
