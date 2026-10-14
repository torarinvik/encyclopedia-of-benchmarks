/* Convert a nonnegative signed 64-bit value with a LIFO digit stack. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t decimal_to_any_using_stack(const std::int64_t *input, std::size_t length,
                                                     std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length != 2) return -1;
    const std::int64_t value = input[0], base = input[1];
    if (value < 0 || base < 2 || base > 16) return -1;
    std::size_t width = 1;
    for (std::int64_t remaining = value; remaining >= base; remaining /= base) ++width;
    if (output == nullptr || output_capacity < width) return -2;
    std::size_t top = 0;
    std::int64_t remaining = value;
    if (remaining == 0) output[top++] = '0';
    while (remaining > 0) {
        const std::int64_t digit = remaining % base;
        output[top++] = static_cast<std::uint8_t>(digit < 10 ? '0' + digit : 'A' + digit - 10);
        remaining /= base;
    }
    for (std::size_t left = 0, right = top - 1; left < right; ++left, --right) {
        const std::uint8_t temporary = output[left];
        output[left] = output[right];
        output[right] = temporary;
    }
    return static_cast<std::int64_t>(top);
}
