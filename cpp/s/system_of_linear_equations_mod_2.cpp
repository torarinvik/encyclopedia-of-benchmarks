#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t kMaxN = 32;
constexpr std::size_t kMaxM = 32;
constexpr std::size_t kMaxInputValues = 2 + kMaxN * kMaxM + kMaxN;

void store_u64_le(std::uint8_t *output, std::size_t offset, std::uint64_t value) {
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}
}

extern "C" std::int64_t system_of_linear_equations_mod_2(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputValues) return -1;
    const auto n_value = input[0];
    const auto m_value = input[1];
    if (n_value < 1 || n_value > 32 || m_value < 1 || m_value > 32) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    if (length != 2 + n * m + n) return -1;

    std::array<std::uint64_t, kMaxN> rows{};
    std::array<std::uint8_t, kMaxN> rhs{};
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column < m; ++column) {
            const auto bit = input[2 + row * m + column];
            if (bit != 0 && bit != 1) return -1;
            rows[row] |= static_cast<std::uint64_t>(bit) << column;
        }
        const auto bit = input[2 + n * m + row];
        if (bit != 0 && bit != 1) return -1;
        rhs[row] = static_cast<std::uint8_t>(bit);
    }

    std::array<std::size_t, kMaxN> pivot_columns{};
    std::size_t pivot_row = 0;
    for (std::size_t column = 0; column < m; ++column) {
        auto pivot = pivot_row;
        while (pivot < n && ((rows[pivot] >> column) & 1u) == 0) ++pivot;
        if (pivot == n) continue;
        std::swap(rows[pivot_row], rows[pivot]);
        std::swap(rhs[pivot_row], rhs[pivot]);
        for (std::size_t row = 0; row < n; ++row) {
            if (row != pivot_row && ((rows[row] >> column) & 1u) != 0) {
                rows[row] ^= rows[pivot_row];
                rhs[row] ^= rhs[pivot_row];
            }
        }
        pivot_columns[pivot_row++] = column;
    }

    for (std::size_t row = pivot_row; row < n; ++row) {
        if (rows[row] == 0 && rhs[row] != 0) {
            if (output == nullptr || capacity < 8) return -2;
            store_u64_le(output, 0, UINT64_MAX);
            return 8;
        }
    }

    std::array<bool, kMaxM> is_pivot{};
    for (std::size_t row = 0; row < pivot_row; ++row) is_pivot[pivot_columns[row]] = true;
    const auto nullity = m - pivot_row;
    const auto output_bytes = 8 * (nullity + 2);
    if (output == nullptr || capacity < output_bytes) return -2;

    std::uint64_t particular = 0;
    for (std::size_t row = 0; row < pivot_row; ++row)
        if (rhs[row] != 0) particular |= std::uint64_t{1} << pivot_columns[row];
    store_u64_le(output, 0, nullity);
    store_u64_le(output, 8, particular);
    std::size_t basis_index = 0;
    for (std::size_t free_column = 0; free_column < m; ++free_column) {
        if (is_pivot[free_column]) continue;
        std::uint64_t basis = std::uint64_t{1} << free_column;
        for (std::size_t row = 0; row < pivot_row; ++row)
            if (((rows[row] >> free_column) & 1u) != 0)
                basis |= std::uint64_t{1} << pivot_columns[row];
        store_u64_le(output, 16 + 8 * basis_index++, basis);
    }
    return static_cast<std::int64_t>(output_bytes);
}
