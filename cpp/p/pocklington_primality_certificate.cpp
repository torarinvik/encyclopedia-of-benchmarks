#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 65535;
constexpr std::int64_t max_factors = 6;
constexpr std::int64_t max_exponent = 16;
constexpr std::size_t max_length = 22;

std::int64_t gcd_i64(std::int64_t left, std::int64_t right) noexcept {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

bool is_prime(std::int64_t value) noexcept {
    if (value < 2) return false;
    for (std::int64_t divisor = 2; divisor * divisor <= value;
         divisor = divisor == 2 ? 3 : divisor + 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

std::int64_t pow_mod(std::int64_t base, std::int64_t exponent,
                     std::int64_t modulus) noexcept {
    std::int64_t result = 1;
    auto factor = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * factor) % modulus;
        factor = (factor * factor) % modulus;
        exponent >>= 1;
    }
    return result;
}

std::int64_t verify_certificate(const std::int64_t* values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_length) return -1;
    const auto n = values[0];
    const auto count = values[1];
    if (n < 3 || n > max_n || count < 1 || count > max_factors) return -1;
    if (length != static_cast<std::size_t>(3 + 3 * count)) return -1;

    std::int64_t factored_part = 1;
    std::int64_t previous_prime = 1;
    for (std::int64_t index = 0; index < count; ++index) {
        const auto offset = static_cast<std::size_t>(2 + 3 * index);
        const auto prime = values[offset];
        const auto exponent = values[offset + 1];
        const auto witness = values[offset + 2];
        if (prime <= previous_prime || prime < 2 || exponent < 1 || exponent > max_exponent
            || witness < 1 || witness >= n || !is_prime(prime)) return -1;
        previous_prime = prime;
        for (std::int64_t power = 0; power < exponent; ++power) {
            if (factored_part > (n - 1) / prime) return -1;
            factored_part *= prime;
        }
    }
    const auto cofactor = values[2 + 3 * count];
    if (cofactor < 1 || cofactor >= n || factored_part * cofactor != n - 1) return -1;
    if (factored_part * factored_part <= n) return 0;

    for (std::int64_t index = 0; index < count; ++index) {
        const auto offset = static_cast<std::size_t>(2 + 3 * index);
        const auto prime = values[offset];
        const auto witness = values[offset + 2];
        if (pow_mod(witness, n - 1, n) != 1) return 0;
        const auto reduced = pow_mod(witness, (n - 1) / prime, n);
        const auto difference = (reduced + n - 1) % n;
        if (gcd_i64(difference, n) != 1) return 0;
    }
    return 1;
}
}

extern "C" std::int64_t pocklington_primality_certificate(
    const std::int64_t* input, std::size_t length) noexcept {
    return verify_certificate(input, length);
}
