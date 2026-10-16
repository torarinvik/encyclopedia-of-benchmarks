#include <stddef.h>
#include <stdint.h>

#define MAX_DIGITS 19
#define MAX_DIGIT_SUM 171
#define MAX_INPUT_LENGTH 4
#define MIN_BOUND (-1LL)
#define MAX_BOUND 1000000000000000000LL

static int64_t count_up_to(int64_t bound, size_t target)
{
    if (bound < 0) return 0;
    size_t digits[MAX_DIGITS] = {0};
    size_t digit_count = 0;
    do {
        digits[digit_count++] = (size_t)(bound % 10);
        bound /= 10;
    } while (bound > 0);

    int64_t loose[MAX_DIGIT_SUM + 1] = {0};
    int64_t tight[MAX_DIGIT_SUM + 1] = {0};
    tight[0] = 1;
    while (digit_count > 0) {
        const size_t limit = digits[--digit_count];
        int64_t next_loose[MAX_DIGIT_SUM + 1] = {0};
        int64_t next_tight[MAX_DIGIT_SUM + 1] = {0};
        for (size_t sum = 0; sum <= target; ++sum) {
            for (size_t digit = 0; digit <= 9 && sum + digit <= target; ++digit)
                next_loose[sum + digit] += loose[sum];
            for (size_t digit = 0; digit <= limit && sum + digit <= target; ++digit) {
                if (digit == limit) next_tight[sum + digit] += tight[sum];
                else next_loose[sum + digit] += tight[sum];
            }
        }
        for (size_t sum = 0; sum <= target; ++sum) {
            loose[sum] = next_loose[sum];
            tight[sum] = next_tight[sum];
        }
    }
    return loose[target] + tight[target];
}

int64_t digit_dp(const int64_t *input, size_t length)
{
    if (input == NULL || length > MAX_INPUT_LENGTH || length != 3) return -1;
    const int64_t lower = input[0], upper = input[1], target_value = input[2];
    if (lower < MIN_BOUND || lower > MAX_BOUND || upper < MIN_BOUND || upper > MAX_BOUND
        || target_value < -2147483648LL || target_value > 2147483647LL) return -1;
    if (lower > upper || target_value < 0 || target_value > MAX_DIGIT_SUM) return 0;
    const size_t target = (size_t)target_value;
    return count_up_to(upper, target) - count_up_to(lower - 1, target);
}
