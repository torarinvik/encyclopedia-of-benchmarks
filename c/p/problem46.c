#include <stdint.h>

#define MAX_ODD_COMPOSITE INT64_C(99999)

static int problem46_is_prime(int64_t number)
{
    if (number < 2) return 0;
    if (number < 4) return 1;
    if (number % 2 == 0 || number % 3 == 0) return 0;
    for (int64_t divisor = 5; divisor <= number / divisor; divisor += 6) {
        if (number % divisor == 0 || number % (divisor + 2) == 0) return 0;
    }
    return 1;
}

static int64_t problem46_find_first_counterexample(void)
{
    for (int64_t candidate = 3; candidate <= MAX_ODD_COMPOSITE; candidate += 2) {
        if (problem46_is_prime(candidate)) continue;
        int represented = 0;
        for (int64_t square = 0; 2 * square * square <= candidate; ++square) {
            if (problem46_is_prime(candidate - 2 * square * square)) {
                represented = 1;
                break;
            }
        }
        if (!represented) return candidate;
    }
    return -1;
}

int64_t problem46(int64_t placeholder)
{
    if (placeholder != 0) return -1;
    return problem46_find_first_counterexample();
}
