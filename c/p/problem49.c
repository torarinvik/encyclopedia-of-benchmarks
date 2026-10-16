/* Concatenate the largest first arithmetic prime-permutation sequence. */
#include <stdbool.h>
#include <stdint.h>

static int64_t digit_signature(int64_t value)
{
    int64_t digits[4] = {value / 1000, value / 100 % 10, value / 10 % 10, value % 10};
    for (int first = 0; first < 4; ++first) {
        for (int second = first + 1; second < 4; ++second) {
            if (digits[first] > digits[second]) {
                const int64_t temporary = digits[first];
                digits[first] = digits[second];
                digits[second] = temporary;
            }
        }
    }
    return digits[0] * 1000 + digits[1] * 100 + digits[2] * 10 + digits[3];
}

int64_t problem49(int64_t ignored)
{
    if (ignored != 0) return -1;
    bool prime_flags[10000] = {false};
    for (int value = 2; value < 10000; ++value) prime_flags[value] = true;
    for (int prime = 2; prime * prime < 10000; ++prime) {
        if (!prime_flags[prime]) continue;
        for (int multiple = prime * prime; multiple < 10000; multiple += prime)
            prime_flags[multiple] = false;
    }

    int64_t primes[1100] = {0};
    int64_t signatures[10000] = {0};
    int prime_count = 0;
    for (int value = 1001; value < 10000; value += 2) {
        if (prime_flags[value]) {
            primes[prime_count++] = value;
            signatures[value] = digit_signature(value);
        }
    }

    bool seen_signatures[10000] = {false};
    int64_t best = 0;
    for (int seed = 0; seed < prime_count; ++seed) {
        const int64_t signature = signatures[primes[seed]];
        if (seen_signatures[signature]) continue;
        seen_signatures[signature] = true;
        int64_t group[24] = {0};
        int group_count = 0;
        for (int candidate = 0; candidate < prime_count; ++candidate) {
            const int64_t value = primes[candidate];
            if (signatures[value] == signature) group[group_count++] = value;
        }
        bool found = false;
        for (int first = 0; first < group_count && !found; ++first) {
            for (int second = first + 1; second < group_count && !found; ++second) {
                for (int third = second + 1; third < group_count; ++third) {
                    if (group[second] - group[first] == group[third] - group[second]) {
                        const int64_t sequence = group[first] * 100000000 +
                                                 group[second] * 10000 + group[third];
                        if (sequence > best) best = sequence;
                        found = true;
                        break;
                    }
                }
            }
        }
    }
    return best;
}
