#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t MaxVertices = 6;
constexpr std::size_t MaxEdges = 12;
constexpr std::size_t MaxInputLength = 27;
constexpr std::int64_t Modulus = 998'244'353;

std::int64_t modular_power(std::int64_t base, std::int64_t exponent) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % Modulus;
        base = (base * base) % Modulus;
        exponent >>= 1;
    }
    return result;
}
} // namespace

extern "C" std::int64_t counting_spanning_trees_directed(
    const std::int64_t* values, std::size_t length,
    std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 3 || length > MaxInputLength) return -1;
    const auto n_value = values[0];
    const auto m_value = values[1];
    const auto root_value = values[2];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(MaxVertices) ||
        m_value < 0 || m_value > static_cast<std::int64_t>(MaxEdges) ||
        root_value < 0 || root_value >= n_value) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto edge_count = static_cast<std::size_t>(m_value);
    const auto root = static_cast<std::size_t>(root_value);
    if (length != 3 + 2 * edge_count) return -1;

    const auto dimension = n - 1;
    std::int64_t matrix[MaxVertices][MaxVertices]{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto u_value = values[3 + 2 * edge];
        const auto v_value = values[4 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value) return -1;
        const auto u = static_cast<std::size_t>(u_value);
        const auto v = static_cast<std::size_t>(v_value);
        if (u == v || v == root) continue;
        const auto row = v < root ? v : v - 1;
        matrix[row][row] = (matrix[row][row] + 1) % Modulus;
        if (u != root) {
            const auto column = u < root ? u : u - 1;
            matrix[row][column] = (matrix[row][column] + Modulus - 1) % Modulus;
        }
    }
    if (output == nullptr || output_capacity < 8) return -2;

    std::int64_t determinant = 1;
    for (std::size_t column = 0; column < dimension; ++column) {
        std::size_t pivot = column;
        while (pivot < dimension && matrix[pivot][column] == 0) ++pivot;
        if (pivot == dimension) { determinant = 0; break; }
        if (pivot != column) {
            for (std::size_t j = 0; j < dimension; ++j)
                std::swap(matrix[column][j], matrix[pivot][j]);
            determinant = (Modulus - determinant) % Modulus;
        }
        const auto pivot_value = matrix[column][column];
        determinant = (determinant * pivot_value) % Modulus;
        const auto inverse = modular_power(pivot_value, Modulus - 2);
        for (std::size_t row = column + 1; row < dimension; ++row) {
            const auto factor = (matrix[row][column] * inverse) % Modulus;
            for (std::size_t j = column; j < dimension; ++j)
                matrix[row][j] = (matrix[row][j] - factor * matrix[column][j] % Modulus + Modulus) % Modulus;
        }
    }
    const auto answer = static_cast<std::uint64_t>(determinant);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(answer >> (8 * byte));
    return 8;
}
