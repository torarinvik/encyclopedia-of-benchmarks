/* Fold a list of nonnegative values with overflow-safe Euclidean LCM. */
#include <stddef.h>
#include <stdint.h>

int64_t lcm_of_n_numbers(const int64_t *values, size_t length)
{
    for (size_t index = 0; index < length; ++index) {
        if (values[index] == 0) return 0;
    }
    uint64_t accumulator = 1;
    const uint64_t maximum = UINT64_C(9223372036854775807);
    for (size_t index = 0; index < length; ++index) {
        uint64_t left = accumulator;
        uint64_t right = (uint64_t)values[index];
        while (right != 0) {
            const uint64_t remainder = left % right;
            left = right;
            right = remainder;
        }
        const uint64_t reduced = accumulator / left;
        const uint64_t value = (uint64_t)values[index];
        if (reduced > maximum / value) return -1;
        accumulator = reduced * value;
    }
    return (int64_t)accumulator;
}
