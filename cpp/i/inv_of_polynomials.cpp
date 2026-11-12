#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_length = 6;
constexpr std::size_t max_input = 14;
constexpr std::size_t capacity = 16;
using Polynomial = std::array<std::int64_t, capacity>;

struct Poly {
    Polynomial coefficients{};
    std::size_t length = 0;
};

std::int64_t power_mod(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent /= 2;
    }
    return result;
}

std::size_t trim(Poly& polynomial, std::size_t length) {
    while (length > 0 && polynomial.coefficients[length - 1] == 0) --length;
    polynomial.length = length;
    return length;
}

std::pair<Poly, Poly> divide_poly(const Poly& dividend, const Poly& divisor) {
    Poly quotient{};
    Poly remainder = dividend;
    trim(remainder, remainder.length);
    if (remainder.length < divisor.length) return {quotient, remainder};
    const auto inverse_lead = power_mod(divisor.coefficients[divisor.length - 1], modulus - 2);
    while (remainder.length >= divisor.length) {
        const auto shift = remainder.length - divisor.length;
        const auto factor = remainder.coefficients[remainder.length - 1] * inverse_lead % modulus;
        quotient.coefficients[shift] = factor;
        for (std::size_t j = 0; j < divisor.length; ++j) {
            auto value = (remainder.coefficients[shift + j] - factor * divisor.coefficients[j]) % modulus;
            if (value < 0) value += modulus;
            remainder.coefficients[shift + j] = value;
        }
        trim(remainder, remainder.length);
    }
    const auto q_bound = dividend.length >= divisor.length
        ? dividend.length - divisor.length + 1 : 0;
    trim(quotient, q_bound);
    return {quotient, remainder};
}

Poly multiply(const Poly& left, const Poly& right) {
    Poly product{};
    if (left.length == 0 || right.length == 0) return product;
    for (std::size_t i = 0; i < left.length; ++i) {
        for (std::size_t j = 0; j < right.length && i + j < capacity; ++j) {
            product.coefficients[i + j] =
                (product.coefficients[i + j] + left.coefficients[i] * right.coefficients[j]) % modulus;
        }
    }
    const auto bound = left.length + right.length - 1 < capacity
        ? left.length + right.length - 1 : capacity;
    trim(product, bound);
    return product;
}

Poly subtract(const Poly& left, const Poly& right) {
    Poly difference{};
    const auto bound = left.length > right.length ? left.length : right.length;
    for (std::size_t i = 0; i < bound; ++i) {
        const auto a = i < left.length ? left.coefficients[i] : 0;
        const auto b = i < right.length ? right.coefficients[i] : 0;
        difference.coefficients[i] = (a - b + modulus) % modulus;
    }
    trim(difference, bound);
    return difference;
}

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t inv_of_polynomials(const std::int64_t* input,
                                              std::size_t length,
                                              std::uint8_t* output,
                                              std::size_t capacity_bytes) noexcept {
    if (input == nullptr || length < 4 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_length)
            || input[1] < 1 || input[1] > static_cast<std::int64_t>(max_length)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + m) return -1;
    Poly f{};
    Poly g{};
    f.length = n;
    g.length = m;
    for (std::size_t i = 0; i < n; ++i) {
        f.coefficients[i] = input[2 + i];
        if (f.coefficients[i] < 0 || f.coefficients[i] >= modulus) return -1;
    }
    for (std::size_t i = 0; i < m; ++i) {
        g.coefficients[i] = input[2 + n + i];
        if (g.coefficients[i] < 0 || g.coefficients[i] >= modulus) return -1;
    }
    if (f.coefficients[n - 1] == 0 || g.coefficients[m - 1] == 0) return -1;

    Poly inverse{};
    if (m > 1) {
        auto initial = divide_poly(f, g).second;
        Poly r0 = g;
        Poly r1 = initial;
        Poly s0{};
        Poly s1{};
        s1.coefficients[0] = 1;
        s1.length = 1;
        while (r1.length > 0) {
            auto [quotient, remainder] = divide_poly(r0, r1);
            const auto next_s = subtract(s0, multiply(quotient, s1));
            r0 = r1;
            r1 = remainder;
            s0 = s1;
            s1 = next_s;
        }
        if (r0.length != 1) return -1;
        const auto scale = power_mod(r0.coefficients[0], modulus - 2);
        for (std::size_t i = 0; i < s0.length; ++i)
            inverse.coefficients[i] = s0.coefficients[i] * scale % modulus;
        trim(inverse, s0.length);
    }

    const auto bytes = 8 * inverse.length;
    if (output == nullptr || capacity_bytes < bytes) return -2;
    for (std::size_t i = 0; i < inverse.length; ++i) store_le(output, 8 * i, inverse.coefficients[i]);
    return static_cast<std::int64_t>(bytes);
}
