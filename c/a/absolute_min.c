#include <stddef.h>
#include <stdint.h>

static int64_t magnitude(int64_t value) { return value < 0 ? -value : value; }

static int64_t select_absolute(const int64_t *values, size_t length, int maximum)
{
    if (length < 2 || length > 257) return -1;
    const int64_t count_value = values[0];
    if (count_value < 1 || count_value > 256 || length != (size_t)count_value + 1) return -1;
    for (size_t index = 1; index < length; ++index) {
        if (values[index] < -1000000000LL || values[index] > 1000000000LL) return -1;
    }
    int64_t best = values[1];
    for (size_t index = 2; index < length; ++index) {
        const int64_t candidate = values[index];
        if (maximum ? (magnitude(candidate) > magnitude(best) || (magnitude(candidate) == magnitude(best) && candidate > best)) : (magnitude(candidate) < magnitude(best) || (magnitude(candidate) == magnitude(best) && candidate < best))) best = candidate;
    }
    return best;
}

int64_t absolute_min_benchmark(const int64_t *values, size_t length)
{
    return select_absolute(values, length, 0);
}
