/* Evaluate the bounded integer binomial expansion exactly. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_EXPONENT = 31;

std::int64_t integer_power(std::int64_t base, std::int64_t exponent) noexcept
{
    std::int64_t result = 1;
    for (std::int64_t index = 0; index < exponent; ++index) result *= base;
    return result;
}

std::int64_t binomial_coefficient(std::int64_t n, std::int64_t k) noexcept
{
    std::int64_t coefficients[MAX_EXPONENT + 1]{};
    coefficients[0] = 1;
    for (std::int64_t row = 1; row <= n; ++row) {
        auto column = row < k ? row : k;
        while (column > 0) {
            coefficients[column] += coefficients[column - 1];
            --column;
        }
    }
    return coefficients[k];
}
}

extern "C" std::int64_t binomial_expansion(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 3) return INT64_MIN;
    const auto a = input[0], b = input[1], exponent = input[2];
    if (a < -2 || a > 2 || b < -2 || b > 2 || exponent < 0 || exponent > MAX_EXPONENT)
        return INT64_MIN;

    std::int64_t result = 0;
    for (std::int64_t index = 0; index <= exponent; ++index) {
        result += binomial_coefficient(exponent, index) *
                  integer_power(a, exponent - index) * integer_power(b, index);
    }
    return result;
}
