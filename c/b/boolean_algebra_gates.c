/* Evaluate the pinned Java source's Boolean gates over a flat 0/1 array. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_COUNT 4096
#define INVALID_RESULT INT64_C(-1)

int64_t boolean_algebra_gates(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_COUNT + 2) return INVALID_RESULT;
    const int64_t gate = values[0];
    const int64_t count = values[1];
    if (gate < 0 || gate > 5 || count < 0 || count > MAX_INPUT_COUNT) return INVALID_RESULT;
    if ((size_t)count != length - 2) return INVALID_RESULT;
    if (gate == 2 && count != 1) return INVALID_RESULT;
    int64_t result = (gate == 0 || gate == 4) ? 1 : 0;
    for (size_t index = 0; index < (size_t)count; ++index) {
        const int64_t bit = values[index + 2];
        if (bit != 0 && bit != 1) return INVALID_RESULT;
        if (gate == 0 || gate == 4) result &= bit;
        else if (gate == 1 || gate == 5) result |= bit;
        else if (gate == 2) result = 1 - bit;
        else result ^= bit;
    }
    if (gate == 4 || gate == 5) result = 1 - result;
    return result;
}
