/* Convert a signed 64-bit integer to canonical negabinary digits. */
#include <cstddef>
#include <cstdint>

static std::int64_t quotient_neg2(std::int64_t value, std::int64_t &digit)
{
    std::int64_t quotient = value / -2;
    digit = value % -2;
    if (digit < 0) { digit += 2; ++quotient; }
    return quotient;
}

extern "C" std::int64_t base_neg2_conversion(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length != 1) return -1;
    std::size_t width = 0; std::int64_t remaining = input[0];
    do { std::int64_t digit; remaining = quotient_neg2(remaining, digit); ++width; } while (remaining != 0);
    if (output == nullptr || output_capacity < width) return -2;
    std::size_t top = 0; remaining = input[0];
    do { std::int64_t digit; remaining = quotient_neg2(remaining, digit); output[top++] = static_cast<std::uint8_t>('0' + digit); } while (remaining != 0);
    for (std::size_t left = 0, right = top - 1; left < right; ++left, --right) {
        const std::uint8_t temporary = output[left]; output[left] = output[right]; output[right] = temporary;
    }
    return static_cast<std::int64_t>(top);
}
