#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_digits = 19;
constexpr std::size_t max_digit_sum = 171;
constexpr std::size_t max_input_length = 4;
constexpr std::int64_t min_bound = -1;
constexpr std::int64_t max_bound = 1'000'000'000'000'000'000LL;

std::int64_t count_up_to(std::int64_t bound, std::size_t target) {
    if (bound < 0) return 0;
    std::array<std::size_t, max_digits> digits{};
    std::size_t digit_count = 0;
    do {
        digits[digit_count++] = static_cast<std::size_t>(bound % 10);
        bound /= 10;
    } while (bound > 0);

    std::array<std::int64_t, max_digit_sum + 1> loose{};
    std::array<std::int64_t, max_digit_sum + 1> tight{};
    tight[0] = 1;
    while (digit_count > 0) {
        const std::size_t limit = digits[--digit_count];
        std::array<std::int64_t, max_digit_sum + 1> next_loose{};
        std::array<std::int64_t, max_digit_sum + 1> next_tight{};
        for (std::size_t sum = 0; sum <= target; ++sum) {
            for (std::size_t digit = 0; digit <= 9 && sum + digit <= target; ++digit)
                next_loose[sum + digit] += loose[sum];
            for (std::size_t digit = 0; digit <= limit && sum + digit <= target; ++digit) {
                if (digit == limit) next_tight[sum + digit] += tight[sum];
                else next_loose[sum + digit] += tight[sum];
            }
        }
        loose = next_loose;
        tight = next_tight;
    }
    return loose[target] + tight[target];
}
}

extern "C" std::int64_t digit_dp(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length > max_input_length || length != 3) return -1;
    const auto lower = input[0], upper = input[1], target_value = input[2];
    if (lower < min_bound || lower > max_bound || upper < min_bound || upper > max_bound
        || target_value < -2147483648LL || target_value > 2147483647LL) return -1;
    if (lower > upper || target_value < 0 || target_value > static_cast<std::int64_t>(max_digit_sum)) return 0;
    const auto target = static_cast<std::size_t>(target_value);
    return count_up_to(upper, target) - count_up_to(lower - 1, target);
}
