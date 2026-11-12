#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxDimension = 64;
constexpr std::size_t kMaxInputValues = 3 + 2 * kMaxDimension * kMaxDimension;
constexpr std::size_t kMaxOutputValues = kMaxDimension * kMaxDimension;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t matrix_product_mod_2(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > kMaxInputValues) return -1;
    const auto n_value = input[0], m_value = input[1], k_value = input[2];
    if (n_value < 1 || n_value > 64 || m_value < 1 || m_value > 64 ||
        k_value < 1 || k_value > 64) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    const auto k = static_cast<std::size_t>(k_value);
    const auto a_length = n * m, b_length = m * k;
    if (length != 3 + a_length + b_length) return -1;

    std::array<std::uint64_t, kMaxDimension> packed_b{};
    const auto b_start = 3 + a_length;
    for (std::size_t inner = 0; inner < m; ++inner) {
        for (std::size_t column = 0; column < k; ++column) {
            const auto bit = input[b_start + inner * k + column];
            if (bit != 0 && bit != 1) return -1;
            packed_b[inner] |= static_cast<std::uint64_t>(bit) << column;
        }
    }

    std::array<std::int64_t, kMaxOutputValues> staged{};
    for (std::size_t row = 0; row < n; ++row) {
        std::uint64_t accumulator = 0;
        for (std::size_t inner = 0; inner < m; ++inner) {
            const auto bit = input[3 + row * m + inner];
            if (bit != 0 && bit != 1) return -1;
            if (bit == 1) accumulator ^= packed_b[inner];
        }
        for (std::size_t column = 0; column < k; ++column)
            staged[row * k + column] = static_cast<std::int64_t>((accumulator >> column) & 1u);
    }

    const auto required = 8 * n * k;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < n * k; ++index)
        store_i64_le(output, 8 * index, staged[index]);
    return static_cast<std::int64_t>(required);
}
