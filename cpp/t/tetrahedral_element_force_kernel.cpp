#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_elements = 32;
constexpr std::size_t max_valid_input = 3 + 12 * max_elements;
constexpr std::size_t max_input = max_valid_input + 1;

void store_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tetrahedral_element_force_kernel(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    const auto m_value = input[0], lambda = input[1], mu = input[2];
    if (m_value < 1 || m_value > static_cast<std::int64_t>(max_elements) ||
        lambda < 0 || lambda > 16 || mu < 0 || mu > 16) return -1;
    const auto m = static_cast<std::size_t>(m_value);
    if (length != 3 + 12 * m) return -1;
    for (std::size_t i = 3; i < length; ++i)
        if (input[i] < -4 || input[i] > 4) return -1;

    const auto required = 96 * m;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t element = 0; element < m; ++element) {
        const auto *coordinates = input + 3 + 12 * element;
        std::int64_t f[3][3]{};
        for (std::size_t row = 0; row < 3; ++row)
            for (std::size_t column = 0; column < 3; ++column)
                f[row][column] = coordinates[3 * (column + 1) + row] - coordinates[row];

        const auto trace_delta = f[0][0] + f[1][1] + f[2][2] - 3;
        std::int64_t stress[3][3]{};
        for (std::size_t row = 0; row < 3; ++row) {
            for (std::size_t column = 0; column < 3; ++column) {
                const std::int64_t diagonal = row == column ? 1 : 0;
                stress[row][column] = lambda * trace_delta * diagonal +
                    mu * (f[row][column] + f[column][row] - 2 * diagonal);
            }
        }
        for (std::size_t axis = 0; axis < 3; ++axis) {
            const auto vertex0 = stress[axis][0] + stress[axis][1] + stress[axis][2];
            store_le(output, 8 * (12 * element + axis), vertex0);
            for (std::size_t vertex = 1; vertex < 4; ++vertex)
                store_le(output, 8 * (12 * element + 3 * vertex + axis),
                         -stress[axis][vertex - 1]);
        }
    }
    return static_cast<std::int64_t>(required);
}
