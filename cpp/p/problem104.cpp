#include <cstddef>
#include <cstdint>

namespace {
constexpr std::uint32_t MAX_FIBONACCI_INDEX = 1'000'002;
constexpr std::size_t MAX_LIMBS = 24'000;
constexpr std::uint32_t LIMB_BASE = 1'000'000'000;

bool is_pandigital_1_to_9(std::uint32_t value)
{
    std::uint16_t mask = 0;
    for (int index = 0; index < 9; ++index) {
        const auto digit = value % 10;
        const auto bit = std::uint16_t(1) << digit;
        if (digit == 0 || (mask & bit) != 0) return false;
        mask |= bit;
        value /= 10;
    }
    return value == 0 && mask == 0x3fe;
}
std::uint32_t power_of_ten(std::uint32_t exponent)
{
    std::uint32_t value = 1;
    while (exponent-- > 0) value *= 10;
    return value;
}
std::uint32_t leading_nine_digits(const std::uint32_t *limbs, std::size_t length)
{
    const auto top = limbs[length - 1];
    std::uint32_t width = 0;
    for (auto value = top; value > 0; value /= 10) ++width;
    if (width >= 9 || length == 1) return top;
    const auto fill = 9 - width;
    const auto next_prefix = limbs[length - 2] / power_of_ten(width);
    return top * power_of_ten(fill) + next_prefix;
}
}

extern "C" std::int64_t problem104(std::int64_t placeholder) noexcept
{
    if (placeholder != 0) return -1;
    std::uint32_t first_buffer[MAX_LIMBS] = {1};
    std::uint32_t second_buffer[MAX_LIMBS] = {1};
    auto *previous = first_buffer;
    auto *current = second_buffer;
    std::size_t previous_length = 1, current_length = 1;

    for (std::uint32_t index = 3; index <= MAX_FIBONACCI_INDEX; ++index) {
        const auto sum_length = previous_length > current_length ? previous_length : current_length;
        std::uint64_t carry = 0;
        for (std::size_t limb = 0; limb < sum_length; ++limb) {
            const std::uint64_t left = limb < previous_length ? previous[limb] : 0;
            const std::uint64_t right = limb < current_length ? current[limb] : 0;
            const auto sum = left + right + carry;
            previous[limb] = static_cast<std::uint32_t>(sum % LIMB_BASE);
            carry = sum / LIMB_BASE;
        }
        auto next_length = sum_length;
        if (carry != 0) {
            if (next_length == MAX_LIMBS) return -1;
            previous[next_length++] = static_cast<std::uint32_t>(carry);
        }
        auto *temporary = previous;
        previous = current;
        current = temporary;
        previous_length = current_length;
        current_length = next_length;
        if (is_pandigital_1_to_9(current[0])
            && is_pandigital_1_to_9(leading_nine_digits(current, current_length))) return index;
    }
    return -1;
}
