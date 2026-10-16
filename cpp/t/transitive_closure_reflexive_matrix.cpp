#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 32;
constexpr std::size_t max_edges = max_vertices * (max_vertices - 1);
constexpr std::size_t max_input_length = 2 + 2 * max_edges;
constexpr std::size_t max_cells = max_vertices * max_vertices;

void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t transitive_closure_reflexive_matrix(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_vertices)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (input[1] < 0 || input[1] > static_cast<std::int64_t>(n * (n - 1))) return -1;
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;

    std::int64_t reach[max_cells] = {};
    for (std::size_t i = 0; i < n; ++i) reach[i * n + i] = 1;
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto from_value = input[2 + 2 * edge];
        const auto to_value = input[3 + 2 * edge];
        if (from_value < 0 || from_value >= static_cast<std::int64_t>(n) || to_value < 0 || to_value >= static_cast<std::int64_t>(n) || from_value == to_value) return -1;
        const auto from = static_cast<std::size_t>(from_value), to = static_cast<std::size_t>(to_value);
        if (reach[from * n + to] != 0) return -1;
        reach[from * n + to] = 1;
    }
    for (std::size_t k = 0; k < n; ++k)
        for (std::size_t i = 0; i < n; ++i)
            if (reach[i * n + k] == 1)
                for (std::size_t j = 0; j < n; ++j)
                    if (reach[k * n + j] == 1) reach[i * n + j] = 1;

    const std::size_t output_bytes = n * n * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < n * n; ++i) put_i64_le(output, i * 8, reach[i]);
    return static_cast<std::int64_t>(output_bytes);
}
