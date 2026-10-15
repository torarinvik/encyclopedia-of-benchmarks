/* Emit the prime characteristic sequence: 1 for primes and 0 otherwise. */
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 4096

static int is_prime(int64_t candidate)
{
    if (candidate < 2) return 0;
    for (int64_t divisor = 2; divisor <= candidate / divisor; ++divisor) {
        if (candidate % divisor == 0) return 0;
    }
    return 1;
}

int64_t binary_prime_constant_sequence(const int64_t *input, size_t length,
                                      uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length != 1 || input[0] < 0 || input[0] > MAX_COUNT) return -1;
    const size_t count = (size_t)input[0];
    if (output_capacity < count || (count != 0 && output == NULL)) return -2;

    size_t next = 1;
    for (int64_t candidate = 2; candidate <= input[0]; ++candidate) {
        if (!is_prime(candidate)) continue;
        while (next < (size_t)candidate) output[next++ - 1] = 0;
        output[(size_t)candidate - 1] = 1;
        next = (size_t)candidate + 1;
    }
    while (next <= count) output[next++ - 1] = 0;
    return (int64_t)count;
}
