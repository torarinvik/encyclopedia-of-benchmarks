#include <cstddef>
#include <cstdint>

namespace {
std::int64_t totient(std::int64_t value) noexcept {
    std::int64_t result = value;
    std::int64_t remaining = value;
    if (remaining % 2 == 0) {
        result -= result / 2;
        do { remaining /= 2; } while (remaining % 2 == 0);
    }
    for (std::int64_t factor = 3; factor <= remaining / factor; factor += 2) {
        if (remaining % factor == 0) {
            result -= result / factor;
            do { remaining /= factor; } while (remaining % factor == 0);
        }
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}

std::int64_t power_capped(std::int64_t base, std::int64_t exponent,
                          std::int64_t cap) noexcept {
    std::int64_t result = 1;
    std::int64_t factor = base < cap ? base : cap;
    while (exponent > 0) {
        if (exponent % 2 != 0) {
            result *= factor;
            if (result >= cap) return cap;
        }
        exponent /= 2;
        if (exponent > 0) {
            factor *= factor;
            if (factor >= cap) factor = cap;
        }
    }
    return result;
}

std::int64_t tower_capped(std::int64_t base, std::int64_t height,
                          std::int64_t cap) noexcept {
    if (height == 0) return 1 < cap ? 1 : cap;
    if (base == 0) return height % 2 == 0 ? 1 : 0;
    if (base == 1) return 1 < cap ? 1 : cap;
    std::int64_t value = 1;
    if (value >= cap) return cap;
    while (height > 0) {
        value = power_capped(base, value, cap);
        if (value >= cap) return cap;
        --height;
    }
    return value;
}

std::int64_t modular_power(std::int64_t base, std::int64_t exponent,
                           std::int64_t modulus) noexcept {
    std::int64_t result = 1 % modulus;
    base %= modulus;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = (result * base) % modulus;
        exponent /= 2;
        base = (base * base) % modulus;
    }
    return result;
}

std::int64_t tetration(std::int64_t base, std::int64_t height,
                       std::int64_t modulus) noexcept {
    if (modulus == 1) return 0;
    if (height == 0) return 1 % modulus;
    if (height == 1) return base % modulus;
    const std::int64_t exponent_modulus = totient(modulus);
    std::int64_t exponent = tetration(base, height - 1, exponent_modulus);
    if (tower_capped(base, height - 1, exponent_modulus) >= exponent_modulus)
        exponent += exponent_modulus;
    return modular_power(base, exponent, modulus);
}
} // namespace

extern "C" std::int64_t tetration_mod(const std::int64_t* input,
                                      std::size_t length) noexcept {
    if (input == nullptr || length != 3) return -1;
    const std::int64_t base = input[0];
    const std::int64_t height = input[1];
    const std::int64_t modulus = input[2];
    if (base < 0 || base > INT64_C(1000000000)
        || height < 0 || height > INT64_C(1000000000)
        || modulus < 1 || modulus > INT64_C(1000000000)) return -1;
    return tetration(base, height, modulus);
}
