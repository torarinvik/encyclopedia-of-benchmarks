#include <stdint.h>

#define MAX_N INT64_C(1000000000000)
#define MAX_ROOT 1000000

static int64_t integer_sqrt(int64_t value) {
    int64_t low = 1;
    int64_t high = MAX_ROOT;
    while (low < high) {
        const int64_t middle = low + (high - low + 1) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle - 1;
    }
    return low;
}

int64_t counting_squarefrees(int64_t n) {
    if (n < 1 || n > MAX_N) return -1;
    const int64_t limit = integer_sqrt(n);
    uint8_t mobius[MAX_ROOT + 1];
    uint8_t composite[MAX_ROOT + 1] = {0};
    for (int64_t value = 1; value <= limit; ++value) mobius[value] = 1;

    for (int64_t prime = 2; prime <= limit; ++prime) {
        if (composite[prime]) continue;
        if (prime <= limit / prime) {
            for (int64_t multiple = prime * prime; multiple <= limit; multiple += prime)
                composite[multiple] = 1;
        }
        for (int64_t multiple = prime; multiple <= limit; multiple += prime) {
            if (mobius[multiple] == 1) mobius[multiple] = 2;
            else if (mobius[multiple] == 2) mobius[multiple] = 1;
        }
        if (prime <= limit / prime) {
            const int64_t square = prime * prime;
            for (int64_t multiple = square; multiple <= limit; multiple += square)
                mobius[multiple] = 0;
        }
    }

    int64_t count = 0;
    for (int64_t divisor = 1; divisor <= limit; ++divisor) {
        const int64_t quotient = n / (divisor * divisor);
        if (mobius[divisor] == 1) count += quotient;
        else if (mobius[divisor] == 2) count -= quotient;
    }
    return count;
}
