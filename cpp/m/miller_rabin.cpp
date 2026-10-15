/* Deterministic Miller-Rabin for signed 32-bit inputs. */
#include <cstdint>

static std::int64_t mod_power(std::int64_t base, std::int64_t exponent,
                              std::int64_t modulus) noexcept
{
    std::int64_t result = 1;
    base %= modulus;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent /= 2;
    }
    return result;
}

static bool passes_base(std::int64_t n, std::int64_t base,
                        std::int64_t odd_part, std::int64_t powers_of_two) noexcept
{
    std::int64_t value = mod_power(base, odd_part, n);
    if (value == 1 || value == n - 1) return true;
    for (std::int64_t round = 1; round < powers_of_two; ++round) {
        value = (value * value) % n;
        if (value == n - 1) return true;
    }
    return false;
}

extern "C" std::int64_t miller_rabin(std::int64_t n) noexcept
{
    if (n < 2) return 0;
    if (n > INT32_MAX) return -1;
    constexpr std::int64_t small_primes[] = {2, 3, 5, 7};
    for (std::int64_t i = 0; i < 4; ++i) {
        if (n == small_primes[i]) return 1;
        if (n % small_primes[i] == 0) return 0;
    }

    std::int64_t odd_part = n - 1;
    std::int64_t powers_of_two = 0;
    while (odd_part % 2 == 0) {
        odd_part /= 2;
        ++powers_of_two;
    }
    for (std::int64_t i = 0; i < 4; ++i) {
        if (!passes_base(n, small_primes[i], odd_part, powers_of_two)) return 0;
    }
    return 1;
}
