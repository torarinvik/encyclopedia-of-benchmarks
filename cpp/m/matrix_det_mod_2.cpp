#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t kMaxN = 64;
constexpr std::size_t kMaxInputValues = 1 + kMaxN * kMaxN;

void store_i64_le(std::uint8_t *output, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t matrix_det_mod_2(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxInputValues) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > 64) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 1 + n * n) return -1;

    std::array<std::uint64_t, kMaxN> rows{};
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            const auto bit = input[1 + row * n + column];
            if (bit != 0 && bit != 1) return -1;
            rows[row] |= static_cast<std::uint64_t>(bit) << column;
        }
    }

    std::size_t pivot_row = 0;
    for (std::size_t column = 0; column < n; ++column) {
        auto pivot = pivot_row;
        while (pivot < n && ((rows[pivot] >> column) & 1u) == 0) ++pivot;
        if (pivot == n) continue;
        std::swap(rows[pivot_row], rows[pivot]);
        for (std::size_t row = pivot_row + 1; row < n; ++row)
            if (((rows[row] >> column) & 1u) != 0) rows[row] ^= rows[pivot_row];
        ++pivot_row;
    }
    if (output == nullptr || capacity < 8) return -2;
    store_i64_le(output, static_cast<std::int64_t>(pivot_row == n));
    return 8;
}
