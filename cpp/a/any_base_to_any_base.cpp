/* Convert a radix digit array through checked decimal accumulation. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t any_base_to_any_base(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 3 || length > 65) return -1;
    const std::int64_t source_base = input[0], target_base = input[1];
    if (source_base < 2 || source_base > 36 || target_base < 2 || target_base > 36) return -1;
    std::int64_t value = 0;
    for (std::size_t index = 2; index < length; ++index) {
        const std::int64_t digit = input[index];
        if (digit < 0 || digit >= source_base || value > (INT64_MAX - digit) / source_base) return -1;
        value = value * source_base + digit;
    }
    std::size_t width = 1;
    for (std::int64_t remaining = value; remaining >= target_base; remaining /= target_base) ++width;
    if (output == nullptr || output_capacity < width) return -2;
    std::size_t top = 0;
    std::int64_t remaining = value;
    if (remaining == 0) output[top++] = '0';
    while (remaining > 0) {
        const std::int64_t digit = remaining % target_base;
        output[top++] = static_cast<std::uint8_t>(digit < 10 ? '0' + digit : 'A' + digit - 10);
        remaining /= target_base;
    }
    for (std::size_t left = 0, right = top - 1; left < right; ++left, --right) {
        const std::uint8_t temporary = output[left]; output[left] = output[right]; output[right] = temporary;
    }
    return static_cast<std::int64_t>(top);
}
