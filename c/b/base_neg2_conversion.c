/* Convert a signed 64-bit integer to canonical negabinary digits. */
#include <stddef.h>
#include <stdint.h>

static int64_t quotient_neg2(int64_t value, int64_t *digit)
{
    int64_t quotient = value / -2;
    *digit = value % -2;
    if (*digit < 0) { *digit += 2; ++quotient; }
    return quotient;
}

int64_t base_neg2_conversion(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length != 1) return -1;
    int64_t width = 0, remaining = input[0];
    do { int64_t digit; remaining = quotient_neg2(remaining, &digit); ++width; } while (remaining != 0);
    if (output == NULL || output_capacity < (size_t)width) return -2;
    size_t top = 0; remaining = input[0];
    do { int64_t digit; remaining = quotient_neg2(remaining, &digit); output[top++] = (uint8_t)('0' + digit); } while (remaining != 0);
    for (size_t left = 0, right = top - 1; left < right; ++left, --right) {
        const uint8_t temporary = output[left]; output[left] = output[right]; output[right] = temporary;
    }
    return (int64_t)top;
}
