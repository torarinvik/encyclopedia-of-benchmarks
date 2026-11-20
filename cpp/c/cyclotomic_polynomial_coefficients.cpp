#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 32;
constexpr std::size_t MAX_INPUT_LENGTH = 2;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t cyclotomic_polynomial_coefficients(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length == 0 || length > MAX_INPUT_LENGTH) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(MAX_N) || length != 1) return -1;
    const auto n = static_cast<std::size_t>(n_value);

    std::int64_t polynomials[MAX_N + 1][MAX_N + 1]{};
    std::size_t degrees[MAX_N + 1]{};
    polynomials[1][0] = -1;
    polynomials[1][1] = 1;
    degrees[1] = 1;
    for (std::size_t k = 2; k <= n; ++k) {
        std::int64_t divisor[MAX_N + 1]{};
        divisor[0] = 1;
        std::size_t divisor_degree = 0;
        for (std::size_t d = 1; d < k; ++d) {
            if (k % d != 0) continue;
            std::int64_t product[MAX_N + 1]{};
            for (std::size_t i = 0; i <= divisor_degree; ++i)
                for (std::size_t j = 0; j <= degrees[d]; ++j)
                    product[i + j] += divisor[i] * polynomials[d][j];
            divisor_degree += degrees[d];
            for (std::size_t i = 0; i <= divisor_degree; ++i) divisor[i] = product[i];
        }
        std::int64_t remainder[MAX_N + 1]{};
        remainder[0] = -1;
        remainder[k] = 1;
        const auto quotient_degree = k - divisor_degree;
        degrees[k] = quotient_degree;
        for (std::size_t q = quotient_degree + 1; q-- > 0;) {
            const auto leading = remainder[divisor_degree + q];
            polynomials[k][q] = leading;
            for (std::size_t j = 0; j <= divisor_degree; ++j)
                remainder[q + j] -= leading * divisor[j];
        }
    }

    const auto coefficient_count = degrees[n] + 1;
    const auto required = coefficient_count * 8;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < coefficient_count; ++index)
        store_i64_le(output, 8 * index, polynomials[n][index]);
    return static_cast<std::int64_t>(required);
}
