#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t factorial_last_nonzero_digit(
    const std::int64_t* input, std::size_t length) noexcept {
    constexpr std::array<std::int64_t, 5> digit_factor{1, 1, 2, 6, 4};
    constexpr std::array<std::int64_t, 4> two_power_mod_10{1, 2, 4, 8};

    if (input == nullptr || length < 1 || length > 2) return -1;
    if (length != 1 || input[0] < 0) return -1;

    std::int64_t n = input[0];
    std::int64_t result = 1;
    while (n >= 5) {
        const std::int64_t quotient = n / 5;
        const std::int64_t remainder = n % 5;
        result = result * digit_factor[static_cast<std::size_t>(remainder)] % 10;
        result = result * two_power_mod_10[static_cast<std::size_t>(quotient % 4)] % 10;
        n = quotient;
    }
    return result * digit_factor[static_cast<std::size_t>(n)] % 10;
}
