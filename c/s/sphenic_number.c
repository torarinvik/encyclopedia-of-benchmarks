#include <stdint.h>

static int source_sieve_flag(int64_t value)
{
    if (value == 1) return 1;
    if (value < 2) return 1;
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

int64_t sphenic_number(int64_t value)
{
    if (value < 0 || value > 1000) return -1;
    int64_t first[3] = {0, 0, 0};
    int64_t count = 0;
    for (int64_t divisor = 1; divisor <= value; ++divisor) {
        if (value % divisor == 0 && count < 9) {
            if (count < 3) first[count] = divisor;
            ++count;
        }
    }
    return count == 8 && source_sieve_flag(first[0])
        && source_sieve_flag(first[1]) && source_sieve_flag(first[2]);
}
