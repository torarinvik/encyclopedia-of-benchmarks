// Count a bounded prefix tree of positive polydivisible numbers.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxBase = 10;
constexpr std::int64_t kMaxDigits = 6;

std::int64_t extend_prefix(std::int64_t prefix, std::int64_t digits,
                           std::int64_t base, std::int64_t max_digits) noexcept {
    std::int64_t count = 1;
    if (digits == max_digits) return count;
    const std::int64_t next_length = digits + 1;
    for (std::int64_t digit = 0; digit < base; ++digit) {
        const auto candidate = prefix * base + digit;
        if (candidate % next_length == 0)
            count += extend_prefix(candidate, next_length, base, max_digits);
    }
    return count;
}
} // namespace

extern "C" std::int64_t polydivisible_prefix_search(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 2) return -1;
    const auto base = input[0];
    const auto max_digits = input[1];
    if (base < 2 || base > kMaxBase || max_digits < 1 || max_digits > kMaxDigits) return -1;
    std::int64_t count = 0;
    for (std::int64_t first_digit = 1; first_digit < base; ++first_digit)
        count += extend_prefix(first_digit, 1, base, max_digits);
    return count;
}
