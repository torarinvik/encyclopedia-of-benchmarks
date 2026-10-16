#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_LIMIT = 10'000'000;
constexpr std::size_t MAX_DIGITS = 7;
constexpr std::size_t MAX_SUM = MAX_DIGITS * 81 + 1;

std::uint32_t digit_square_sum(std::uint32_t value)
{
    std::uint32_t total = 0;
    while (value != 0) {
        const auto digit = value % 10;
        total += digit * digit;
        value /= 10;
    }
    return total;
}

bool reaches_89(std::uint32_t value)
{
    while (value != 1 && value != 89) value = digit_square_sum(value);
    return value == 89;
}
}

extern "C" std::int64_t problem92(std::int64_t number) noexcept
{
    if (number < 0 || number > MAX_LIMIT) return -1;
    std::array<std::uint32_t, MAX_DIGITS> digits{}, reversed{};
    std::size_t digit_count = 0;
    if (number > 1) {
        auto remaining = static_cast<std::uint32_t>(number - 1);
        while (remaining != 0) { reversed[digit_count++] = remaining % 10; remaining /= 10; }
        for (std::size_t index = 0; index < digit_count; ++index) digits[index] = reversed[digit_count - index - 1];
    } else {
        digits[digit_count++] = 0;
    }
    const std::size_t sum_limit = digit_count * 81 + 1;
    std::array<std::int64_t, MAX_SUM> tight{}, free_counts{}, next_tight{}, next_free{};
    tight[0] = 1;
    for (std::size_t position = 0; position < digit_count; ++position) {
        next_tight.fill(0);
        next_free.fill(0);
        const auto bound_digit = digits[position];
        for (std::size_t sum = 0; sum < sum_limit; ++sum) {
            if (tight[sum] != 0) {
                for (std::uint32_t digit = 0; digit <= bound_digit; ++digit) {
                    const auto next_sum = sum + digit * digit;
                    if (next_sum >= sum_limit) continue;
                    if (digit == bound_digit) next_tight[next_sum] += tight[sum];
                    else next_free[next_sum] += tight[sum];
                }
            }
            if (free_counts[sum] != 0) {
                for (std::uint32_t digit = 0; digit <= 9; ++digit) {
                    const auto next_sum = sum + digit * digit;
                    if (next_sum < sum_limit) next_free[next_sum] += free_counts[sum];
                }
            }
        }
        tight = next_tight;
        free_counts = next_free;
    }
    std::int64_t result = 0;
    for (std::uint32_t sum = 1; sum < sum_limit; ++sum)
        if (reaches_89(sum)) result += tight[sum] + free_counts[sum];
    return result;
}
