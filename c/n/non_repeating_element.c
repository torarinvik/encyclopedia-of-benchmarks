#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64
#define MAX_VALUE INT64_C(1073741823)

int64_t non_repeating_element(const int64_t *values, size_t length)
{
    if (length < 2 || length > MAX_LENGTH || (length & 1u) != 0) return -1;
    int32_t xor_result = 0;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > MAX_VALUE) return -1;
        xor_result ^= (int32_t)values[index];
    }
    const int32_t rightmost_set_bit = xor_result & -xor_result;
    int32_t num1 = 0;
    int32_t num2 = 0;
    for (size_t index = 0; index < length; ++index) {
        const int32_t value = (int32_t)values[index];
        if ((value & rightmost_set_bit) != 0) num1 ^= value;
        else num2 ^= value;
    }
    return ((int64_t)num1 << 32) | (uint32_t)num2;
}
