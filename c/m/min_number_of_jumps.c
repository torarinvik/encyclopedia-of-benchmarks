#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64
#define UNREACHABLE INT64_C(1000000000000)

int64_t min_number_of_jumps(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_LENGTH) return -1;
    for (size_t i = 0; i < length; ++i) if (values[i] < 0 || values[i] > MAX_LENGTH) return -1;
    int64_t jumps[MAX_LENGTH];
    for (size_t i = 0; i < MAX_LENGTH; ++i) jumps[i] = UNREACHABLE;
    jumps[0] = 0;
    for (size_t i = 1; i < length; ++i) {
        for (size_t j = 0; j < i; ++j) {
            if (values[j] + (int64_t)j >= (int64_t)i && jumps[j] + 1 < jumps[i]) jumps[i] = jumps[j] + 1;
        }
    }
    return jumps[length - 1];
}
