#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT INT64_C(30)
#define MAX_TARGET INT64_C(64)
#define MAX_VALUE INT64_C(64)
#define MAX_INPUT_LENGTH ((size_t)33)
#define INVALID_RESULT INT64_C(-1)

int64_t subset_count(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;

    const int64_t count_value = values[0];
    const int64_t target = values[1];
    if (count_value < 1 || count_value > MAX_COUNT || target < 0 || target > MAX_TARGET ||
        length != (size_t)count_value + 2) return INVALID_RESULT;

    for (int64_t index = 0; index < count_value; ++index) {
        const int64_t value = values[(size_t)index + 2];
        if (value < 0 || value > MAX_VALUE) return INVALID_RESULT;
    }

    int64_t previous[65] = {0};
    previous[0] = 1;
    if (values[2] <= target) previous[values[2]] = 1;

    for (int64_t index = 1; index < count_value; ++index) {
        int64_t current[65] = {0};
        current[0] = 1;
        for (int64_t amount = 1; amount <= target; ++amount) {
            const int64_t not_taken = previous[amount];
            const int64_t value = values[(size_t)index + 2];
            const int64_t taken = value <= amount ? previous[amount - value] : 0;
            current[amount] = not_taken + taken;
        }
        for (int64_t amount = 0; amount <= target; ++amount) previous[amount] = current[amount];
    }
    return previous[target];
}
