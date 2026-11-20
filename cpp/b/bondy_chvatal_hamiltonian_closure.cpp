#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxVertices = 8;
constexpr int kMaxEdges = 28;
constexpr std::size_t kMaxInputWords = 59;
constexpr std::size_t kMaxOutputWords = 10;

int degree_of(const std::array<std::array<bool, kMaxVertices>, kMaxVertices> &adjacency,
              int vertex, int n) {
    int degree = 0;
    for (int other = 0; other < n; ++other) degree += adjacency[vertex][other];
    return degree;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t bondy_chvatal_hamiltonian_closure(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputWords) return -1;
    const auto n_word = input[0], m_word = input[1];
    if (n_word < 3 || n_word > kMaxVertices || m_word < 0 || m_word > kMaxEdges) return -1;
    const int n = static_cast<int>(n_word), m = static_cast<int>(m_word);
    if (m > n * (n - 1) / 2 || length != static_cast<std::size_t>(2 + 2 * m)) return -1;

    std::array<std::array<bool, kMaxVertices>, kMaxVertices> adjacency{};
    for (int edge = 0; edge < m; ++edge) {
        const auto u_word = input[2 + 2 * edge], v_word = input[3 + 2 * edge];
        if (u_word < 0 || u_word >= n || v_word < 0 || v_word >= n || u_word == v_word) return -1;
        const int u = static_cast<int>(u_word), v = static_cast<int>(v_word);
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = adjacency[v][u] = true;
    }

    int added = 0;
    for (;;) {
        std::array<int, kMaxVertices> degree{};
        for (int vertex = 0; vertex < n; ++vertex)
            degree[vertex] = degree_of(adjacency, vertex, n);
        int chosen_u = -1, chosen_v = -1;
        for (int u = 0; u < n && chosen_u < 0; ++u) {
            for (int v = u + 1; v < n; ++v) {
                if (!adjacency[u][v] && degree[u] + degree[v] >= n) {
                    chosen_u = u;
                    chosen_v = v;
                    break;
                }
            }
        }
        if (chosen_u < 0) break;
        adjacency[chosen_u][chosen_v] = adjacency[chosen_v][chosen_u] = true;
        ++added;
    }

    std::array<std::int64_t, kMaxOutputWords> staged{};
    const unsigned all_vertices = (1u << n) - 1u;
    bool complete = true;
    for (int u = 0; u < n; ++u) {
        unsigned row = 0;
        for (int v = 0; v < n; ++v)
            if (adjacency[u][v]) row |= 1u << v;
        staged[2 + u] = row;
        if (row != (all_vertices ^ (1u << u))) complete = false;
    }
    staged[0] = static_cast<std::int64_t>(complete);
    staged[1] = added;

    const std::size_t output_bytes = static_cast<std::size_t>(2 + n) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t word = 0; word < static_cast<std::size_t>(2 + n); ++word)
        store_i64_le(output, word * 8, staged[word]);
    return static_cast<std::int64_t>(output_bytes);
}
