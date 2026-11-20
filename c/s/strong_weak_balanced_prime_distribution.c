#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_LIMIT = 100000, SIEVE_LENGTH = 200001, MAX_PARSEABLE_LENGTH = 2 };

int64_t strong_weak_balanced_prime_distribution(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t limit = input[0];
    if (length != 1 || limit < 3 || limit > MAX_LIMIT) return -1;

    const int64_t ceiling = 2 * limit;
    uint8_t prime[SIEVE_LENGTH];
    memset(prime, 1, sizeof(prime));
    prime[0] = prime[1] = 0;
    for (int64_t divisor = 2; divisor * divisor <= ceiling; ++divisor) {
        if (!prime[divisor]) continue;
        for (int64_t multiple = divisor * divisor; multiple <= ceiling; multiple += divisor)
            prime[multiple] = 0;
    }

    int64_t strong = 0, weak = 0, balanced = 0;
    int64_t previous = 0, current = 0;
    for (int64_t candidate = 2; candidate <= ceiling; ++candidate) {
        if (!prime[candidate]) continue;
        if (previous != 0 && current >= 3 && current <= limit) {
            const int64_t twice = 2 * current;
            const int64_t neighbors = previous + candidate;
            if (twice > neighbors) ++strong;
            else if (twice < neighbors) ++weak;
            else ++balanced;
        }
        previous = current;
        current = candidate;
    }
    return strong * 10000000000LL + weak * 100000LL + balanced;
}
