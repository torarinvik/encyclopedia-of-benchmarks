/* Convert a radix digit array through checked decimal accumulation. */
#include <stddef.h>
#include <stdint.h>

int64_t any_base_to_any_base(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 3 || length > 65) return -1;
    const int64_t source_base = input[0], target_base = input[1];
    if (source_base < 2 || source_base > 36 || target_base < 2 || target_base > 36) return -1;
    int64_t value = 0;
    for (size_t index = 2; index < length; ++index) {
        const int64_t digit = input[index];
        if (digit < 0 || digit >= source_base || value > (INT64_MAX - digit) / source_base) return -1;
        value = value * source_base + digit;
    }
    size_t width = 1;
    for (int64_t remaining = value; remaining >= target_base; remaining /= target_base) ++width;
    if (output == NULL || output_capacity < width) return -2;
    size_t top = 0;
    int64_t remaining = value;
    if (remaining == 0) output[top++] = '0';
    while (remaining > 0) {
        const int64_t digit = remaining % target_base;
        output[top++] = (uint8_t)(digit < 10 ? '0' + digit : 'A' + digit - 10);
        remaining /= target_base;
    }
    for (size_t left = 0, right = top - 1; left < right; ++left, --right) {
        const uint8_t temporary = output[left]; output[left] = output[right]; output[right] = temporary;
    }
    return (int64_t)top;
}
