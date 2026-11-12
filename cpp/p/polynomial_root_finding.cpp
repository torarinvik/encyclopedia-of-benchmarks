#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr int MAX_N = 8;
constexpr int MAX_PRODUCT = 17;
constexpr std::size_t MAX_INPUT = 10;
constexpr std::int64_t MODULUS = 998244353;
constexpr std::int64_t PRNG_MODULUS = 2147483647;
constexpr int RANDOM_ATTEMPTS = 32;

struct Polynomial {
    std::array<std::int64_t, MAX_PRODUCT> c{};
    int degree = -1;
};

std::int64_t normalize(std::int64_t value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

std::int64_t power_mod(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

void trim(Polynomial& value) {
    while (value.degree >= 0 && value.c[static_cast<std::size_t>(value.degree)] == 0) --value.degree;
}

Polynomial zero_poly() { return Polynomial{}; }

Polynomial poly_mod(Polynomial value, const Polynomial& divisor) {
    if (divisor.degree <= 0 || value.degree < 0) return zero_poly();
    const auto inverse = power_mod(divisor.c[static_cast<std::size_t>(divisor.degree)], MODULUS - 2);
    while (value.degree >= divisor.degree) {
        const int shift = value.degree - divisor.degree;
        const auto factor = value.c[static_cast<std::size_t>(value.degree)] * inverse % MODULUS;
        for (int i = 0; i <= divisor.degree; ++i) {
            const auto at = static_cast<std::size_t>(shift + i);
            value.c[at] = normalize(value.c[at] - factor * divisor.c[static_cast<std::size_t>(i)]);
        }
        trim(value);
    }
    return value;
}

Polynomial multiply_mod(const Polynomial& left, const Polynomial& right,
                        const Polynomial& modulus_poly) {
    if (left.degree < 0 || right.degree < 0) return zero_poly();
    std::array<std::int64_t, MAX_PRODUCT> product{};
    for (int i = 0; i <= left.degree; ++i)
        for (int j = 0; j <= right.degree; ++j) {
            auto& coefficient = product[static_cast<std::size_t>(i + j)];
            coefficient = (coefficient + left.c[static_cast<std::size_t>(i)] *
                           right.c[static_cast<std::size_t>(j)]) % MODULUS;
        }
    Polynomial expanded;
    expanded.degree = left.degree + right.degree;
    expanded.c = product;
    trim(expanded);
    return poly_mod(expanded, modulus_poly);
}

Polynomial polynomial_power_mod(Polynomial base, std::int64_t exponent,
                                const Polynomial& modulus_poly) {
    Polynomial result;
    result.c[0] = 1;
    result.degree = 0;
    base = poly_mod(base, modulus_poly);
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = multiply_mod(result, base, modulus_poly);
        base = multiply_mod(base, base, modulus_poly);
        exponent >>= 1;
    }
    return result;
}

Polynomial polynomial_gcd(Polynomial left, Polynomial right) {
    while (right.degree >= 0) {
        auto remainder = poly_mod(left, right);
        left = right;
        right = remainder;
    }
    if (left.degree < 0) return left;
    const auto inverse = power_mod(left.c[static_cast<std::size_t>(left.degree)], MODULUS - 2);
    for (int i = 0; i <= left.degree; ++i)
        left.c[static_cast<std::size_t>(i)] = left.c[static_cast<std::size_t>(i)] * inverse % MODULUS;
    return left;
}

Polynomial divide_exact(Polynomial value, const Polynomial& divisor) {
    Polynomial quotient;
    quotient.degree = value.degree - divisor.degree;
    if (quotient.degree < 0) return zero_poly();
    const auto inverse = power_mod(divisor.c[static_cast<std::size_t>(divisor.degree)], MODULUS - 2);
    while (value.degree >= divisor.degree) {
        const int shift = value.degree - divisor.degree;
        const auto factor = value.c[static_cast<std::size_t>(value.degree)] * inverse % MODULUS;
        quotient.c[static_cast<std::size_t>(shift)] = factor;
        for (int i = 0; i <= divisor.degree; ++i) {
            const auto at = static_cast<std::size_t>(shift + i);
            value.c[at] = normalize(value.c[at] - factor * divisor.c[static_cast<std::size_t>(i)]);
        }
        trim(value);
    }
    trim(quotient);
    return quotient;
}

bool split_with_affine(const Polynomial& polynomial, std::int64_t slope,
                       std::int64_t offset, Polynomial& first, Polynomial& second) {
    Polynomial affine;
    affine.c[0] = offset;
    affine.c[1] = slope;
    affine.degree = 1;
    affine = poly_mod(affine, polynomial);
    auto powered = polynomial_power_mod(affine, (MODULUS - 1) / 2, polynomial);
    if (powered.degree < 0) {
        powered.c[0] = MODULUS - 1;
        powered.degree = 0;
    } else {
        powered.c[0] = normalize(powered.c[0] - 1);
    }
    trim(powered);
    auto part = polynomial_gcd(polynomial, powered);
    if (part.degree <= 0 || part.degree >= polynomial.degree) return false;
    first = part;
    second = divide_exact(polynomial, part);
    return true;
}

void collect_roots(const Polynomial& polynomial, std::array<std::int64_t, MAX_N>& roots,
                   int& root_count, std::int64_t state) {
    if (polynomial.degree == 1) {
        roots[static_cast<std::size_t>(root_count++)] = normalize(
            -polynomial.c[0] * power_mod(polynomial.c[1], MODULUS - 2));
        return;
    }
    Polynomial first, second;
    for (int attempt = 0; attempt < RANDOM_ATTEMPTS; ++attempt) {
        state = state * 48271 % PRNG_MODULUS;
        auto slope = state % MODULUS;
        if (slope == 0) slope = 1;
        state = state * 48271 % PRNG_MODULUS;
        const auto offset = state % MODULUS;
        if (split_with_affine(polynomial, slope, offset, first, second)) {
            collect_roots(first, roots, root_count, state);
            collect_roots(second, roots, root_count, state + 1);
            return;
        }
    }
    for (std::int64_t offset = 0; offset < MODULUS; ++offset) {
        if (split_with_affine(polynomial, 1, offset, first, second)) {
            collect_roots(first, roots, root_count, state);
            collect_roots(second, roots, root_count, state + offset + 1);
            return;
        }
    }
}

int find_roots(Polynomial polynomial, std::array<std::int64_t, MAX_N>& roots) {
    if (polynomial.degree <= 0) return 0;
    Polynomial x;
    x.c[1] = 1;
    x.degree = 1;
    const auto x_mod = poly_mod(x, polynomial);
    auto x_to_p = polynomial_power_mod(x_mod, MODULUS, polynomial);
    const int largest = x_to_p.degree > x_mod.degree ? x_to_p.degree : x_mod.degree;
    for (int i = 0; i <= largest; ++i) {
        const auto left = i <= x_to_p.degree ? x_to_p.c[static_cast<std::size_t>(i)] : 0;
        const auto right = i <= x_mod.degree ? x_mod.c[static_cast<std::size_t>(i)] : 0;
        x_to_p.c[static_cast<std::size_t>(i)] = normalize(left - right);
    }
    x_to_p.degree = largest;
    trim(x_to_p);
    auto linear_part = polynomial_gcd(polynomial, x_to_p);
    if (linear_part.degree <= 0) return 0;
    std::int64_t seed = 1;
    for (int i = 0; i <= polynomial.degree; ++i)
        seed = (seed * 31 + polynomial.c[static_cast<std::size_t>(i)]) % (PRNG_MODULUS - 1) + 1;
    int root_count = 0;
    collect_roots(linear_part, roots, root_count, seed);
    for (int i = 0; i < root_count; ++i)
        for (int j = i + 1; j < root_count; ++j)
            if (roots[static_cast<std::size_t>(j)] < roots[static_cast<std::size_t>(i)])
                std::swap(roots[static_cast<std::size_t>(i)], roots[static_cast<std::size_t>(j)]);
    return root_count;
}

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
} // namespace

extern "C" std::int64_t polynomial_root_finding(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > MAX_INPUT || input[0] < 0 ||
        input[0] > MAX_N || length != static_cast<std::size_t>(input[0]) + 2) return -1;
    Polynomial polynomial;
    polynomial.degree = static_cast<int>(input[0]);
    for (int i = 0; i <= polynomial.degree; ++i) {
        if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
        polynomial.c[static_cast<std::size_t>(i)] = input[i + 1];
    }
    if (polynomial.c[static_cast<std::size_t>(polynomial.degree)] == 0) return -1;
    std::array<std::int64_t, MAX_N> roots{};
    const int root_count = find_roots(polynomial, roots);
    const auto bytes = 8U * static_cast<std::size_t>(root_count + 1);
    if (output == nullptr || capacity < bytes) return -2;
    store_le(output, 0, root_count);
    for (int i = 0; i < root_count; ++i)
        store_le(output, 8U * static_cast<std::size_t>(i + 1), roots[static_cast<std::size_t>(i)]);
    return static_cast<std::int64_t>(bytes);
}
