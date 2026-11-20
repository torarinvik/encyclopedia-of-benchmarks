#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int field = 7;
constexpr std::size_t max_n = 7;
constexpr std::size_t max_k = 3;
constexpr std::size_t poly_size = 8;
using Polynomial = std::array<int, poly_size>;

int mod7(int value) noexcept {
    value %= field;
    return value < 0 ? value + field : value;
}

int inverse7(int value) noexcept {
    constexpr int inverses[7] = {0, 1, 4, 5, 2, 3, 6};
    return inverses[value];
}

bool is_zero(const Polynomial &polynomial) noexcept {
    for (const int coefficient : polynomial)
        if (coefficient != 0) return false;
    return true;
}

std::size_t degree(const Polynomial &polynomial) noexcept {
    for (std::size_t index = poly_size; index > 0; --index)
        if (polynomial[index - 1] != 0) return index - 1;
    return 0;
}

void multiply_linear(Polynomial &polynomial, int root) noexcept {
    Polynomial product{};
    for (std::size_t index = 0; index < poly_size; ++index) {
        product[index] = mod7(product[index] - root * polynomial[index]);
        if (index + 1 < poly_size)
            product[index + 1] = mod7(product[index + 1] + polynomial[index]);
    }
    polynomial = product;
}

Polynomial interpolate(std::size_t n, const std::array<std::int64_t, max_n> &values) noexcept {
    Polynomial result{};
    for (std::size_t i = 0; i < n; ++i) {
        Polynomial basis{};
        basis[0] = 1;
        int denominator = 1;
        for (std::size_t j = 0; j < n; ++j) {
            if (j == i) continue;
            multiply_linear(basis, static_cast<int>(j));
            denominator = mod7(denominator * (static_cast<int>(i) - static_cast<int>(j)));
        }
        const int scale = mod7(static_cast<int>(values[i]) * inverse7(denominator));
        for (std::size_t index = 0; index < poly_size; ++index)
            result[index] = mod7(result[index] + scale * basis[index]);
    }
    return result;
}

Polynomial vanishing_polynomial(std::size_t n) noexcept {
    Polynomial result{};
    result[0] = 1;
    for (std::size_t point = 0; point < n; ++point)
        multiply_linear(result, static_cast<int>(point));
    return result;
}

bool divide(const Polynomial &numerator, const Polynomial &denominator,
            Polynomial &quotient, Polynomial &remainder) noexcept {
    if (is_zero(denominator)) return false;
    quotient.fill(0);
    remainder = numerator;
    const std::size_t denominator_degree = degree(denominator);
    std::size_t remainder_degree = degree(remainder);
    const int inverse_lead = inverse7(denominator[denominator_degree]);
    while (!is_zero(remainder) && remainder_degree >= denominator_degree) {
        const std::size_t shift = remainder_degree - denominator_degree;
        const int factor = mod7(remainder[remainder_degree] * inverse_lead);
        quotient[shift] = mod7(quotient[shift] + factor);
        for (std::size_t index = 0; index <= denominator_degree; ++index)
            remainder[shift + index] = mod7(
                remainder[shift + index] - factor * denominator[index]);
        remainder_degree = degree(remainder);
    }
    return true;
}

Polynomial multiply(const Polynomial &left, const Polynomial &right) noexcept {
    Polynomial product{};
    for (std::size_t i = 0; i < poly_size; ++i)
        for (std::size_t j = 0; j < poly_size && i + j < poly_size; ++j)
            product[i + j] = mod7(product[i + j] + left[i] * right[j]);
    return product;
}

Polynomial subtract(const Polynomial &left, const Polynomial &right) noexcept {
    Polynomial result{};
    for (std::size_t index = 0; index < poly_size; ++index)
        result[index] = mod7(left[index] - right[index]);
    return result;
}

std::int64_t decode(std::size_t n, std::size_t k, std::size_t errors,
                    const std::array<std::int64_t, max_n> &received) noexcept {
    const Polynomial interpolant = interpolate(n, received);
    if (is_zero(interpolant)) return 1;

    Polynomial r0 = vanishing_polynomial(n);
    Polynomial r1 = interpolant;
    Polynomial v0{};
    Polynomial v1{};
    v1[0] = 1;
    Polynomial candidate_numerator{};
    Polynomial candidate_denominator{};
    bool found = false;
    while (!is_zero(r1)) {
        if (2 * degree(r1) < n + k) {
            candidate_numerator = r1;
            candidate_denominator = v1;
            found = true;
            break;
        }
        Polynomial quotient{}, remainder{};
        if (!divide(r0, r1, quotient, remainder)) return 0;
        if (is_zero(remainder)) break;
        const Polynomial v2 = subtract(v0, multiply(quotient, v1));
        r0 = r1;
        r1 = remainder;
        v0 = v1;
        v1 = v2;
    }
    if (!found || is_zero(candidate_denominator)) return 0;

    Polynomial coefficients{}, division_remainder{};
    if (!divide(candidate_numerator, candidate_denominator,
                coefficients, division_remainder)
        || !is_zero(division_remainder) || degree(coefficients) >= k) return 0;
    std::size_t mismatches = 0;
    for (std::size_t x = 0; x < n; ++x) {
        int value = 0;
        for (std::size_t index = k; index > 0; --index)
            value = (value * static_cast<int>(x) + coefficients[index - 1]) % field;
        if (value != received[x]) ++mismatches;
    }
    if (mismatches > errors) return 0;

    std::int64_t result = 1;
    std::int64_t place = 1;
    for (std::size_t index = 0; index < k; ++index) {
        result += coefficients[index] * place;
        place *= field;
    }
    return result;
}
} // namespace

extern "C" std::int64_t gao_rs_decode(const std::int64_t *input,
                                       std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 11) return -1;
    const std::int64_t n_value = input[0];
    const std::int64_t k_value = input[1];
    const std::int64_t t_value = input[2];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(max_n)
        || k_value < 1 || k_value > static_cast<std::int64_t>(max_k)
        || k_value > n_value || t_value < 0 || t_value > 2
        || 2 * t_value > n_value - k_value) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    const std::size_t k = static_cast<std::size_t>(k_value);
    const std::size_t errors = static_cast<std::size_t>(t_value);
    if (length != 3 + n) return -1;
    std::array<std::int64_t, max_n> received{};
    for (std::size_t index = 0; index < n; ++index) {
        const std::int64_t symbol = input[3 + index];
        if (symbol < 0 || symbol >= field) return -1;
        received[index] = symbol;
    }
    return decode(n, k, errors, received);
}
