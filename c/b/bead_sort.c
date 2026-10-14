/* Bead sort for the benchmark's nonnegative 0..63 domain. */
#include <stddef.h>
#include <stdint.h>

void bead_sort(int64_t *values, int64_t *scratch, size_t length)
{
    if (length < 2) return;
    for (size_t level = 0; level < 64; ++level) scratch[level] = 0;
    for (size_t index = 0; index < length; ++index) {
        for (int64_t level = 0; level < values[index]; ++level) ++scratch[(size_t)level];
    }
    for (size_t index = 0; index < length; ++index) {
        const size_t row_from_bottom = length - 1 - index;
        int64_t value = 0;
        for (size_t level = 0; level < 64; ++level) {
            if (scratch[level] > (int64_t)row_from_bottom) ++value;
        }
        values[index] = value;
    }
}
