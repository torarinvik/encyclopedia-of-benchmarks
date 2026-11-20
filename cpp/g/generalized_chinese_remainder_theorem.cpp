#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_product = 16777216;

std::int64_t modular_inverse(std::int64_t value, std::int64_t modulus) {
    std::int64_t old_remainder = value % modulus, remainder = modulus;
    std::int64_t old_coefficient = 1, coefficient = 0;
    while (remainder != 0) {
        const auto quotient = old_remainder / remainder;
        const auto next_remainder = old_remainder - quotient * remainder;
        old_remainder = remainder;
        remainder = next_remainder;
        const auto next_coefficient = old_coefficient - quotient * coefficient;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    old_coefficient %= modulus;
    return old_coefficient < 0 ? old_coefficient + modulus : old_coefficient;
}
}

extern "C" std::int64_t generalized_chinese_remainder_theorem(const std::int64_t *input,
                                                                 std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 10) return -1;
    const auto count = input[0];
    if (count < 1 || count > 4 || length != static_cast<std::size_t>(1 + 2 * count)) return -1;
    std::int64_t product = 1;
    for (std::int64_t index = 0; index < count; ++index) {
        const auto residue = input[1 + 2 * index];
        const auto modulus = input[2 + 2 * index];
        if (modulus < 2 || modulus > 64 || residue < 0 || residue >= modulus) return -1;
        if (product > max_product / modulus) return -1;
        product *= modulus;
    }

    std::int64_t powers[65]{};
    std::int64_t residues[65]{};
    for (std::int64_t index = 0; index < count; ++index) {
        const auto residue = input[1 + 2 * index];
        auto remaining = input[2 + 2 * index];
        for (std::int64_t prime = 2; prime <= remaining; ++prime) {
            if (remaining % prime != 0) continue;
            std::int64_t prime_power = 1;
            do {
                remaining /= prime;
                prime_power *= prime;
            } while (remaining % prime == 0);
            if (prime_power > powers[prime]) {
                powers[prime] = prime_power;
                residues[prime] = residue % prime_power;
            }
        }
    }
    for (std::int64_t index = 0; index < count; ++index) {
        const auto residue = input[1 + 2 * index];
        auto remaining = input[2 + 2 * index];
        for (std::int64_t prime = 2; prime <= remaining; ++prime) {
            if (remaining % prime != 0) continue;
            std::int64_t prime_power = 1;
            do {
                remaining /= prime;
                prime_power *= prime;
            } while (remaining % prime == 0);
            if (residues[prime] % prime_power != residue % prime_power) return -2;
        }
    }

    std::int64_t solution = 0, combined_modulus = 1;
    for (std::int64_t prime = 2; prime <= 64; ++prime) {
        const auto modulus = powers[prime];
        if (modulus == 0) continue;
        const auto inverse = modular_inverse(combined_modulus % modulus, modulus);
        auto difference = (residues[prime] - solution % modulus) % modulus;
        if (difference < 0) difference += modulus;
        const auto multiplier = difference * inverse % modulus;
        solution += combined_modulus * multiplier;
        combined_modulus *= modulus;
        solution %= combined_modulus;
    }
    return solution;
}
