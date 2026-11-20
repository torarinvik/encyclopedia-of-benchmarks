#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_prime = 1'000'003;

struct ExtensionValue {
    std::int64_t real;
    std::int64_t radical;
};

std::int64_t mod_pow(std::int64_t base, std::int64_t exponent,
                     std::int64_t modulus) {
    std::int64_t result = 1;
    base %= modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

int legendre_symbol(std::int64_t value, std::int64_t prime) {
    const auto symbol = mod_pow(value % prime, (prime - 1) / 2, prime);
    return symbol == prime - 1 ? -1 : static_cast<int>(symbol);
}

ExtensionValue multiply(ExtensionValue left, ExtensionValue right,
                        std::int64_t radicand, std::int64_t prime) {
    return {
        (left.real * right.real + radicand * left.radical * right.radical) % prime,
        (left.real * right.radical + left.radical * right.real) % prime,
    };
}

ExtensionValue extension_pow(ExtensionValue base, std::int64_t exponent,
                             std::int64_t radicand, std::int64_t prime) {
    ExtensionValue result{1, 0};
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = multiply(result, base, radicand, prime);
        base = multiply(base, base, radicand, prime);
        exponent >>= 1;
    }
    return result;
}
}

extern "C" std::int64_t cipolla_modular_square_root(
    const std::int64_t *packed, std::size_t length) noexcept {
    if (packed == nullptr || length != 2) return -1;
    const auto residue = packed[0], prime = packed[1];
    if (prime < 3 || prime > max_prime || (prime & 1) == 0 ||
        residue < 0 || residue >= prime) return -1;
    if (residue == 0) return 0;
    if (legendre_symbol(residue, prime) != 1) return -1;

    for (std::int64_t parameter = 0; parameter < prime; ++parameter) {
        auto radicand = (parameter * parameter - residue) % prime;
        if (radicand < 0) radicand += prime;
        if (legendre_symbol(radicand, prime) == -1) {
            const auto root = extension_pow(
                {parameter, 1}, (prime + 1) / 2, radicand, prime);
            if (root.radical != 0) return -1;
            return root.real < prime - root.real ? root.real : prime - root.real;
        }
    }
    return -1;
}
