/* Search odd divisors for the first source repunit length exceeding limit. */
#include <stdint.h>

#define MAX_LIMIT INT64_C(1000000)

static int64_t least_divisible_repunit(int64_t divisor)
{
    if (divisor % 5 == 0 || divisor % 2 == 0) return 0;
    int64_t repunit = 1;
    int64_t repunit_index = 1;
    while (repunit != 0) {
        repunit = (10 * repunit + 1) % divisor;
        ++repunit_index;
    }
    return repunit_index;
}

int64_t problem129(int64_t limit)
{
    if (limit < 1 || limit > MAX_LIMIT) return -1;
    int64_t divisor = limit - 1;
    if (divisor % 2 == 0) ++divisor;
    while (least_divisible_repunit(divisor) <= limit) divisor += 2;
    return divisor;
}
