/* Convert a nonnegative signed 64-bit value with a LIFO digit stack. */
#include <stddef.h>
#include <stdint.h>

int64_t decimal_to_any_using_stack(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length != 2) return -1;
    const int64_t value = input[0], base = input[1];
    if (value < 0 || base < 2 || base > 16) return -1;
    size_t width = 1;
    for (int64_t remaining = value; remaining >= base; remaining /= base) ++width;
    if (output == NULL || output_capacity < width) return -2;
    size_t top = 0;
    int64_t remaining = value;
    if (remaining == 0) output[top++] = '0';
    while (remaining > 0) {
        const int64_t digit = remaining % base;
        output[top++] = (uint8_t)(digit < 10 ? '0' + digit : 'A' + digit - 10);
        remaining /= base;
    }
    for (size_t left = 0, right = top - 1; left < right; ++left, --right) {
        const uint8_t temporary = output[left];
        output[left] = output[right];
        output[right] = temporary;
    }
    return (int64_t)top;
}
