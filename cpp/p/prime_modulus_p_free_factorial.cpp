#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_prime = 1009;
constexpr std::size_t max_parseable_length = 3;

bool is_prime(std::int64_t value) noexcept {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    for (std::int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}
}

extern "C" std::int64_t prime_modulus_p_free_factorial(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length || length != 2) return -1;
    const std::int64_t n = input[0];
    const std::int64_t prime = input[1];
    if (n < 0 || prime < 2 || prime > max_prime || !is_prime(prime)) return -1;

    std::int64_t factorial[max_prime];
    factorial[0] = 1;
    for (std::int64_t i = 1; i < prime; ++i)
        factorial[i] = factorial[i - 1] * i % prime;

    std::int64_t result = 1;
    std::int64_t remaining = n;
    while (remaining > 0) {
        const std::int64_t quotient = remaining / prime;
        const std::int64_t residue = remaining % prime;
        result = result * factorial[residue] % prime;
        if ((quotient & 1) != 0) result = prime - result;
        remaining = quotient;
    }
    return result;
}
