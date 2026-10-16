/* Preserve the pinned sigma2 behavior, including omission of divisor 1. */
#include <array>
#include <cstdint>

namespace {
constexpr std::int64_t max_limit = 1000;
constexpr std::int64_t mod_limit = 1'000'000'000;
using Divisors = std::array<std::int64_t, 128>;
bool contains(std::int64_t value, const Divisors& divisors, std::int64_t length) noexcept {
    for (std::int64_t i = 0; i < length; ++i) if (divisors[std::size_t(i)] == value) return true;
    return false;
}
std::int64_t get_divisors(std::int64_t number, Divisors& divisors) noexcept {
    if (number == 1) { divisors[0] = 1; return 1; }
    std::int64_t count = 0;
    for (std::int64_t i = 1; i * i <= number + 1; ++i) if (number % i == 0) {
        const auto quotient = number / i;
        if (!contains(i, divisors, count)) divisors[std::size_t(count++)] = i;
        if (!contains(quotient, divisors, count)) divisors[std::size_t(count++)] = quotient;
    }
    return count;
}
std::int64_t sigma2_source(std::int64_t number) noexcept {
    Divisors divisors{};
    const auto count = get_divisors(number, divisors);
    std::int64_t sum = 0;
    for (std::int64_t i = 1; i < count; ++i) sum += (divisors[std::size_t(i)] * divisors[std::size_t(i)]) % mod_limit;
    return sum % mod_limit;
}
}
extern "C" std::int64_t problem401(std::int64_t limit) noexcept {
    if (limit < 0 || limit > max_limit) return -1;
    std::int64_t sum = 0;
    for (std::int64_t number = 0; number <= limit; ++number) sum += sigma2_source(number);
    return sum % mod_limit;
}
