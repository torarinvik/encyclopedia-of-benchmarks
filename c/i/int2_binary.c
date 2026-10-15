/* Encode the C# uint overload as exactly 32 ASCII binary digits. */
#include <stddef.h>
#include <stdint.h>

int64_t int2_binary(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 0 || (uint64_t)value > UINT32_MAX) return -1;
    if (output == NULL || output_capacity < 32) return -2;

    uint32_t remaining = (uint32_t)value;
    uint32_t most_significant_bit = UINT32_C(0x80000000);
    for (size_t i = 0; i < 32; ++i) {
        if (remaining >= most_significant_bit) {
            output[i] = (uint8_t)'1';
            remaining -= most_significant_bit;
        } else {
            output[i] = (uint8_t)'0';
        }
        most_significant_bit /= 2;
    }
    return 32;
}
