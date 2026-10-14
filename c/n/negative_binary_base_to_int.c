/* Interpret most-significant-first bits in radix -2 with checked i64 folding. */
#include <stddef.h>
#include <stdint.h>

int64_t negative_binary_base_to_int(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 63) return -1;
    int64_t value = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t bit = input[index];
        if (bit != 0 && bit != 1) return -1;
        if (value > INT64_C(4611686018427387904) || value < -INT64_C(4611686018427387903)) return -1;
        value = value * -2 + bit;
    }
    return value;
}
