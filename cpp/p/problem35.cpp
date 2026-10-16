/* Count circular primes below one million using an odd-only sieve. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_limit = 1'000'000;
constexpr std::size_t odd_slots = max_limit / 2 + 1;
}

extern "C" std::int64_t problem35(std::int64_t ignored) noexcept
{
    if (ignored != 0) return -1;
    bool odd_prime[odd_slots] = {};
    for (std::size_t index = 1; index < odd_slots; ++index) odd_prime[index] = true;

    for (std::int64_t candidate = 3; candidate <= max_limit / candidate; candidate += 2) {
        if (odd_prime[candidate / 2]) {
            for (std::int64_t composite = candidate * candidate; composite <= max_limit;
                 composite += 2 * candidate) {
                odd_prime[composite / 2] = false;
            }
        }
    }

    std::int64_t count = 1;
    for (std::int64_t number = 3; number <= max_limit; number += 2) {
        if (!odd_prime[number / 2]) continue;
        auto remaining = number;
        bool has_even_digit = false;
        while (remaining > 0) {
            if ((remaining % 10) % 2 == 0) {
                has_even_digit = true;
                break;
            }
            remaining /= 10;
        }
        if (has_even_digit) continue;

        std::int64_t power10 = 1;
        std::int64_t digits = 1;
        remaining = number;
        while (remaining >= 10) {
            power10 *= 10;
            remaining /= 10;
            ++digits;
        }
        auto rotation = number;
        bool circular = true;
        for (std::int64_t turn = 0; turn < digits; ++turn) {
            if (!odd_prime[rotation / 2]) {
                circular = false;
                break;
            }
            rotation = (rotation % 10) * power10 + rotation / 10;
        }
        if (circular) ++count;
    }
    return count;
}
