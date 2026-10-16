/* Search in ascending order for a full period of distinct residues. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

int64_t primitive_root(const int64_t *input, size_t length)
{
    if (input == NULL || length != 1 || input[0] < 2 || input[0] > 127) return -1;
    const int64_t modulus = input[0];
    for (int64_t candidate = 1; candidate < modulus; ++candidate) {
        bool seen[127] = {false};
        int64_t power = 1;
        bool distinct = true;
        for (int64_t exponent = 0; exponent < modulus - 1; ++exponent) {
            if (seen[power]) { distinct = false; break; }
            seen[power] = true;
            power = (power * candidate) % modulus;
        }
        if (distinct) return candidate;
    }
    return 0;
}
