#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_t = 8;
constexpr std::int64_t max_k = 1'000'000'000;
constexpr std::int64_t max_p = 1'000;

std::int64_t modular_power(std::int64_t base, std::int64_t exponent,
                           std::int64_t modulus) noexcept {
    std::int64_t result = 1 % modulus;
    base %= modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

bool is_prime(std::int64_t value) noexcept {
    if (value < 2) return false;
    for (std::int64_t divisor = 2; divisor * divisor <= value; ++divisor)
        if (value % divisor == 0) return false;
    return true;
}

std::size_t factor_distinct(std::int64_t value, std::int64_t *factors) noexcept {
    std::size_t count = 0;
    for (std::int64_t divisor = 2; divisor * divisor <= value; ++divisor) {
        if (value % divisor != 0) continue;
        factors[count++] = divisor;
        do value /= divisor; while (value % divisor == 0);
    }
    if (value > 1) factors[count++] = value;
    return count;
}

std::int64_t primitive_root(std::int64_t prime) noexcept {
    if (prime == 2) return 1;
    const auto order = prime - 1;
    std::int64_t factors[16];
    const auto count = factor_distinct(order, factors);
    for (std::int64_t candidate = 2; candidate < prime; ++candidate) {
        std::size_t i = 0;
        while (i < count && modular_power(candidate, order / factors[i], prime) != 1) ++i;
        if (i == count) return candidate;
    }
    return -1;
}

std::int64_t gcd_i64(std::int64_t a, std::int64_t b) noexcept {
    while (b != 0) {
        const auto remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

std::int64_t modular_inverse(std::int64_t value, std::int64_t modulus) noexcept {
    std::int64_t old_t = 0, new_t = 1, old_r = modulus, new_r = value % modulus;
    while (new_r != 0) {
        const auto quotient = old_r / new_r;
        const auto next_t = old_t - quotient * new_t;
        const auto next_r = old_r - quotient * new_r;
        old_t = new_t;
        new_t = next_t;
        old_r = new_r;
        new_r = next_r;
    }
    if (old_t < 0) old_t += modulus;
    return old_t;
}

std::int64_t kth_root(std::int64_t exponent, std::int64_t residue,
                      std::int64_t prime) noexcept {
    if (exponent == 0) return residue == 1 ? 0 : -1;
    if (residue == 0) return 0;
    const auto order = prime - 1;
    const auto generator = primitive_root(prime);
    std::int64_t power = 1, discrete_log = -1;
    for (std::int64_t candidate = 0; candidate < order; ++candidate) {
        if (power == residue) {
            discrete_log = candidate;
            break;
        }
        power = power * generator % prime;
    }
    if (discrete_log < 0) return -1;

    const auto common = gcd_i64(exponent, order);
    if (discrete_log % common != 0) return -1;
    const auto reduced_order = order / common;
    std::int64_t root_exponent = 0;
    if (reduced_order > 1) {
        const auto inverse = modular_inverse((exponent / common) % reduced_order, reduced_order);
        root_exponent = (discrete_log / common) * inverse % reduced_order;
    }
    const auto root = modular_power(generator, root_exponent, prime);
    return modular_power(root, exponent, prime) == residue ? root : -1;
}

void write_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t kth_root_mod(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > 1 + 3 * max_t) return -1;
    const auto t64 = input[0];
    if (t64 < 1 || t64 > static_cast<std::int64_t>(max_t)) return -1;
    const auto t = static_cast<std::size_t>(t64);
    if (length != 1 + 3 * t) return -1;

    std::int64_t triples[3 * max_t]{};
    for (std::size_t i = 0; i < 3 * t; i += 3) {
        const auto exponent = input[i + 1], residue = input[i + 2], prime = input[i + 3];
        if (exponent < 0 || exponent > max_k || prime < 2 || prime > max_p ||
            residue < 0 || residue >= prime || !is_prime(prime)) return -1;
        triples[i] = exponent;
        triples[i + 1] = residue;
        triples[i + 2] = prime;
    }
    const auto required = 8 * t;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t test = 0; test < t; ++test)
        write_i64(output, 8 * test,
                  kth_root(triples[3 * test], triples[3 * test + 1], triples[3 * test + 2]));
    return static_cast<std::int64_t>(required);
}
