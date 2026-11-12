#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 6;
constexpr std::int64_t kModulus = 998244353;

std::int64_t minor_determinant(const std::array<std::int64_t, kMaxN * kMaxN>& matrix,
                               std::size_t n, std::size_t skip_row,
                               std::size_t skip_column) {
    const std::size_t dimension = n - 1;
    if (dimension == 0) return 1;

    std::array<std::int64_t, kMaxN * kMaxN> minor{};
    std::size_t target_row = 0;
    for (std::size_t row = 0; row < n; ++row) {
        if (row == skip_row) continue;
        std::size_t target_column = 0;
        for (std::size_t column = 0; column < n; ++column) {
            if (column == skip_column) continue;
            minor[target_row * dimension + target_column] = matrix[row * n + column];
            ++target_column;
        }
        ++target_row;
    }

    std::array<std::int64_t, 1U << (kMaxN - 1)> dp{};
    dp[0] = 1;
    const std::size_t limit = std::size_t{1} << dimension;
    for (std::size_t mask = 0; mask < limit; ++mask) {
        std::size_t row = 0;
        for (std::size_t bits = mask; bits != 0; bits >>= 1) row += bits & 1U;
        if (row == dimension) continue;
        for (std::size_t column = 0; column < dimension; ++column) {
            if ((mask & (std::size_t{1} << column)) != 0) continue;
            std::size_t inversions = 0;
            for (std::size_t prior = column + 1; prior < dimension; ++prior)
                inversions += (mask >> prior) & 1U;
            const auto next = mask | (std::size_t{1} << column);
            const auto term = dp[mask] * minor[row * dimension + column] % kModulus;
            const auto signed_term = (inversions & 1U) ? -term : term;
            dp[next] = (dp[next] + signed_term + kModulus) % kModulus;
        }
    }
    return dp[limit - 1];
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t adjugate_matrix(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 1 + kMaxN * kMaxN) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + n * n) return -1;

    std::array<std::int64_t, kMaxN * kMaxN> matrix{};
    for (std::size_t index = 0; index < n * n; ++index) {
        const auto value = input[1 + index];
        if (value < 0 || value >= kModulus) return -1;
        matrix[index] = value;
    }

    const auto output_bytes = 8 * n * n;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            auto value = minor_determinant(matrix, n, column, row);
            if ((row + column) & 1U) value = value == 0 ? 0 : kModulus - value;
            store_i64_le(output, 8 * (row * n + column), value);
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
