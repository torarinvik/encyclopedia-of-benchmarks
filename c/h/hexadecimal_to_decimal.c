/* Convert most-significant-first hexadecimal digits to a signed 64-bit value. */
#include <stddef.h>
#include <stdint.h>

int64_t hexadecimal_to_decimal(const int64_t *digits, size_t length)
{
    if (length == 0 || length > 16) return -1;
    if (length == 16 && digits[0] > 7) return -1;
    int64_t result = 0;
    for (size_t index = 0; index < length; ++index) {
        if (digits[index] < 0 || digits[index] > 15) return -1;
        result = result * 16 + digits[index];
    }
    return result;
}
