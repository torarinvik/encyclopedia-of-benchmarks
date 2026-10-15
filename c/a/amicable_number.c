#include <stdint.h>

static uint64_t proper_divisor_sum(uint64_t number)
{
    if (number <= 1) return 0;
    uint64_t sum = 1;
    for (uint64_t divisor = 2; divisor <= number / divisor; ++divisor) {
        if (number % divisor == 0) {
            sum += divisor;
            const uint64_t partner = number / divisor;
            if (partner != divisor) sum += partner;
        }
    }
    return sum;
}

int64_t amicable_number(uint64_t left, uint64_t right)
{
    if (left < 1 || left > UINT64_C(1000000000)
            || right < 1 || right > UINT64_C(1000000000)) return -1;
    if (left == right) return 0;
    return proper_divisor_sum(left) == right && proper_divisor_sum(right) == left;
}
