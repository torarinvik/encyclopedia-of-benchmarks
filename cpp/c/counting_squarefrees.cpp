#include <array>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 1'000'000'000'000;
constexpr std::size_t max_root = 1'000'000;

std::int64_t integer_sqrt(std::int64_t value) noexcept {
    std::int64_t low = 1;
    std::int64_t high = static_cast<std::int64_t>(max_root);
    while (low < high) {
        const auto middle = low + (high - low + 1) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle - 1;
    }
    return low;
}
} // namespace

extern "C" std::int64_t counting_squarefrees(std::int64_t n) noexcept {
    if (n < 1 || n > max_n) return -1;
    const auto limit = integer_sqrt(n);
    std::array<std::uint8_t, max_root + 1> mobius{};
    std::array<std::uint8_t, max_root + 1> composite{};
    for (std::int64_t value = 1; value <= limit; ++value)
        mobius[static_cast<std::size_t>(value)] = 1;

    for (std::int64_t prime = 2; prime <= limit; ++prime) {
        if (composite[static_cast<std::size_t>(prime)] != 0) continue;
        if (prime <= limit / prime) {
            for (auto multiple = prime * prime; multiple <= limit; multiple += prime)
                composite[static_cast<std::size_t>(multiple)] = 1;
        }
        for (auto multiple = prime; multiple <= limit; multiple += prime) {
            auto& value = mobius[static_cast<std::size_t>(multiple)];
            if (value == 1) value = 2;
            else if (value == 2) value = 1;
        }
        if (prime <= limit / prime) {
            const auto square = prime * prime;
            for (auto multiple = square; multiple <= limit; multiple += square)
                mobius[static_cast<std::size_t>(multiple)] = 0;
        }
    }

    std::int64_t count = 0;
    for (std::int64_t divisor = 1; divisor <= limit; ++divisor) {
        const auto coefficient = mobius[static_cast<std::size_t>(divisor)];
        const auto quotient = n / (divisor * divisor);
        if (coefficient == 1) count += quotient;
        else if (coefficient == 2) count -= quotient;
    }
    return count;
}
