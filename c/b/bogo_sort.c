/* Deterministic bogo sort for the shared, bounded portable workload. */
#include <stddef.h>
#include <stdint.h>

static int bogo_is_sorted(const int64_t *values, size_t length)
{
    for (size_t index = 1; index < length; ++index) {
        if (values[index - 1] > values[index]) return 0;
    }
    return 1;
}

void bogo_sort(int64_t *values, size_t length)
{
    if (length < 2) return;
    uint64_t state = UINT64_C(2654435769);
    while (!bogo_is_sorted(values, length)) {
        for (size_t index = length - 1; index > 0; --index) {
            state = (state * UINT64_C(1664525) + UINT64_C(1013904223)) % UINT64_C(4294967296);
            const size_t other = (size_t)((state / UINT64_C(65536)) % (uint64_t)(index + 1));
            const int64_t temporary = values[index];
            values[index] = values[other];
            values[other] = temporary;
        }
    }
}
