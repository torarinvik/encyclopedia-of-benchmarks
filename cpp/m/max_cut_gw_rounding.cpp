#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 16, MAX_M = 120, MAX_D = 4, MAX_INPUT = 431;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t max_cut_gw_rounding(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > MAX_INPUT) return -1;
    const auto n64 = input[0], m64 = input[1], d64 = input[2];
    if (n64 < 2 || n64 > 16 || m64 < 0 || m64 > 120 || d64 < 1 || d64 > 4 ||
        length != 3 + 3 * static_cast<std::size_t>(m64) + static_cast<std::size_t>(n64) * static_cast<std::size_t>(d64) + static_cast<std::size_t>(d64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64), d = static_cast<std::size_t>(d64);
    std::int64_t edge_u[MAX_M]{}, edge_v[MAX_M]{}, edge_weight[MAX_M]{};
    std::int64_t previous_u = -1, previous_v = -1;
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u = input[3 + 3 * edge], v = input[4 + 3 * edge], weight = input[5 + 3 * edge];
        if (u < 0 || v <= u || v >= n64 || weight < 1 || weight > 10000 ||
            u < previous_u || (u == previous_u && v <= previous_v)) return -1;
        previous_u = u; previous_v = v;
        edge_u[edge] = u; edge_v[edge] = v; edge_weight[edge] = weight;
    }
    const std::size_t vector_offset = 3 + 3 * m;
    std::int64_t vectors[MAX_N][MAX_D]{}, normal[MAX_D]{};
    std::int64_t common_norm = 0;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        std::int64_t norm = 0;
        for (std::size_t axis = 0; axis < d; ++axis) {
            const auto coordinate = input[vector_offset + vertex * d + axis];
            if (coordinate < -100 || coordinate > 100) return -1;
            vectors[vertex][axis] = coordinate;
            norm += coordinate * coordinate;
        }
        if (vertex == 0) common_norm = norm;
        else if (norm != common_norm) return -1;
    }
    if (common_norm == 0) return -1;
    bool has_normal = false;
    for (std::size_t axis = 0; axis < d; ++axis) {
        normal[axis] = input[vector_offset + n * d + axis];
        if (normal[axis] < -100 || normal[axis] > 100) return -1;
        has_normal = has_normal || normal[axis] != 0;
    }
    if (!has_normal) return -1;
    const std::size_t output_bytes = 8 * (n + 1);
    if (output == nullptr || capacity < output_bytes) return -2;
    std::int64_t side[MAX_N]{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        std::int64_t projection = 0;
        for (std::size_t axis = 0; axis < d; ++axis) projection += vectors[vertex][axis] * normal[axis];
        side[vertex] = projection > 0 ? 1 : 0;
    }
    std::int64_t cut = 0;
    for (std::size_t edge = 0; edge < m; ++edge)
        if (side[edge_u[edge]] != side[edge_v[edge]]) cut += edge_weight[edge];
    store_i64_le(output, 0, cut);
    for (std::size_t vertex = 0; vertex < n; ++vertex) store_i64_le(output, 8 * (vertex + 1), side[vertex]);
    return static_cast<std::int64_t>(output_bytes);
}
