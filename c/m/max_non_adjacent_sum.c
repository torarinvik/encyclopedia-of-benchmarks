#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN
#define MAX_N 100000

int64_t max_non_adjacent_sum(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_N) return INVALID_RESULT;
    int64_t two_back = 0;
    int64_t one_back = 0;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < 0 || values[i] > 10000) return INVALID_RESULT;
        const int64_t take = two_back + values[i];
        const int64_t current = take > one_back ? take : one_back;
        two_back = one_back;
        one_back = current;
    }
    return one_back;
}
