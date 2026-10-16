/* Find the numerator of the closest bounded fraction below a reduced target. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_DENOMINATOR = 1'000'000;

std::int64_t gcd_positive(std::int64_t left, std::int64_t right) noexcept
{
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}
}

extern "C" std::int64_t problem71(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 3) return -1;
    const auto target_numerator = input[0];
    const auto target_denominator = input[1];
    const auto limit = input[2];
    if (target_numerator < 1 || target_denominator <= target_numerator ||
        target_denominator > MAX_DENOMINATOR || limit < 1 || limit > MAX_DENOMINATOR ||
        gcd_positive(target_numerator, target_denominator) != 1) return -1;

    std::int64_t best_numerator = 0;
    std::int64_t best_denominator = 1;
    for (std::int64_t current_denominator = 1; current_denominator <= limit; ++current_denominator) {
        auto current_numerator = current_denominator * target_numerator / target_denominator;
        if (current_denominator % target_denominator == 0) --current_numerator;
        if (current_numerator * best_denominator > current_denominator * best_numerator) {
            best_numerator = current_numerator;
            best_denominator = current_denominator;
        }
    }
    return best_numerator;
}
