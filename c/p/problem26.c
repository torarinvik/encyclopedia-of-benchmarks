/* Bounded port of TheAlgorithms/Python Project Euler 26 remainder search. */
#include <stdint.h>

int64_t problem26(int64_t limit)
{
    if (limit < 0 || limit > 1000) return -1;
    int64_t best_denominator = 1;
    int64_t longest_remainder_list = 0;
    for (int64_t denominator = 1; denominator <= limit; ++denominator) {
        unsigned char seen[1001] = {0};
        int64_t remainder = 1;
        int64_t remainder_count = 0;
        for (int64_t step = 0; step < limit; ++step) {
            if (seen[remainder]) {
                if (remainder_count > longest_remainder_list) {
                    longest_remainder_list = remainder_count;
                    best_denominator = denominator;
                }
                break;
            }
            seen[remainder] = 1;
            ++remainder_count;
            remainder = (remainder * 10) % denominator;
        }
    }
    return best_denominator;
}
