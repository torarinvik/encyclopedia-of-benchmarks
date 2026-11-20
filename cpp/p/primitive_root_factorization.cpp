#include <cstddef>
#include <cstdint>

namespace {
bool is_prime(std::int64_t value) {
    if (value < 2) return false;
    for (std::int64_t divisor = 2; divisor * divisor <= value; ++divisor)
        if (value % divisor == 0) return false;
    return true;
}

std::int64_t power_mod(std::int64_t base, std::int64_t exponent, std::int64_t modulus) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}
}

extern "C" std::int64_t primitive_root_factorization(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length != 1 || input[0] < 2 || input[0] > 4093 || !is_prime(input[0])) return -1;
    const std::int64_t prime = input[0];
    if (prime == 2) return 1;

    std::int64_t factors[16]{};
    std::size_t factor_count = 0;
    std::int64_t remaining = prime - 1;
    for (std::int64_t divisor = 2; divisor * divisor <= remaining; ++divisor) {
        if (remaining % divisor == 0) {
            factors[factor_count++] = divisor;
            do { remaining /= divisor; } while (remaining % divisor == 0);
        }
    }
    if (remaining > 1) factors[factor_count++] = remaining;

    for (std::int64_t candidate = 2; candidate < prime; ++candidate) {
        bool valid = true;
        for (std::size_t index = 0; index < factor_count; ++index) {
            if (power_mod(candidate, (prime - 1) / factors[index], prime) == 1) {
                valid = false;
                break;
            }
        }
        if (valid) return candidate;
    }
    return -1;
}
