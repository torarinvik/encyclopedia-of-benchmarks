#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_LIMIT = 10000000, MAX_DIGITS = 7, MAX_SUM = MAX_DIGITS * 81 + 1 };

static uint32_t digit_square_sum(uint32_t value)
{
    uint32_t total = 0;
    while (value != 0) {
        const uint32_t digit = value % 10;
        total += digit * digit;
        value /= 10;
    }
    return total;
}

static int reaches_89(uint32_t value)
{
    while (value != 1 && value != 89) value = digit_square_sum(value);
    return value == 89;
}

int64_t problem92(int64_t number)
{
    if (number < 0 || number > MAX_LIMIT) return -1;
    uint32_t digits[MAX_DIGITS], reversed[MAX_DIGITS];
    size_t digit_count = 0;
    if (number > 1) {
        uint32_t remaining = (uint32_t)number - 1;
        while (remaining != 0) { reversed[digit_count++] = remaining % 10; remaining /= 10; }
        for (size_t index = 0; index < digit_count; ++index) digits[index] = reversed[digit_count - index - 1];
    } else {
        digits[digit_count++] = 0;
    }
    const size_t sum_limit = digit_count * 81 + 1;
    int64_t tight[MAX_SUM] = {0}, free_counts[MAX_SUM] = {0};
    int64_t next_tight[MAX_SUM], next_free[MAX_SUM];
    tight[0] = 1;
    for (size_t position = 0; position < digit_count; ++position) {
        memset(next_tight, 0, sizeof(next_tight));
        memset(next_free, 0, sizeof(next_free));
        const uint32_t bound_digit = digits[position];
        for (size_t sum = 0; sum < sum_limit; ++sum) {
            if (tight[sum] != 0) {
                for (uint32_t digit = 0; digit <= bound_digit; ++digit) {
                    const size_t next_sum = sum + digit * digit;
                    if (next_sum >= sum_limit) continue;
                    if (digit == bound_digit) next_tight[next_sum] += tight[sum];
                    else next_free[next_sum] += tight[sum];
                }
            }
            if (free_counts[sum] != 0) {
                for (uint32_t digit = 0; digit <= 9; ++digit) {
                    const size_t next_sum = sum + digit * digit;
                    if (next_sum < sum_limit) next_free[next_sum] += free_counts[sum];
                }
            }
        }
        memcpy(tight, next_tight, sizeof(tight));
        memcpy(free_counts, next_free, sizeof(free_counts));
    }
    int64_t result = 0;
    for (uint32_t sum = 1; sum < sum_limit; ++sum)
        if (reaches_89(sum)) result += tight[sum] + free_counts[sum];
    return result;
}
