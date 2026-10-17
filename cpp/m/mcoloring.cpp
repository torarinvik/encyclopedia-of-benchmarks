#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxVertices = 14;
constexpr std::size_t kMaxParseableInputLength = 17;

int find_root(int parent[kMaxVertices], int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}
}

extern "C" std::int64_t mcoloring(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2 || length > kMaxParseableInputLength) return -1;
    const std::int64_t n_value = input[0], colors_value = input[1];
    if (n_value < 0 || n_value > kMaxVertices || colors_value < 1 || colors_value > kMaxVertices) return -1;
    const int n = static_cast<int>(n_value);
    if (length != static_cast<std::size_t>(n) + 2) return -1;

    std::uint32_t masks[kMaxVertices]{};
    const std::uint32_t valid_mask = n == 0 ? 0u : (1u << n) - 1u;
    int parent[kMaxVertices];
    for (int vertex = 0; vertex < n; ++vertex) {
        const std::int64_t raw = input[vertex + 2];
        if (raw < 0 || static_cast<std::uint64_t>(raw) > valid_mask) return -1;
        masks[vertex] = static_cast<std::uint32_t>(raw);
        if (masks[vertex] & (1u << vertex)) return -1;
        parent[vertex] = vertex;
    }
    for (int vertex = 0; vertex < n; ++vertex) {
        for (int neighbor = vertex + 1; neighbor < n; ++neighbor) {
            const bool edge = (masks[vertex] & (1u << neighbor)) != 0;
            if (edge != ((masks[neighbor] & (1u << vertex)) != 0)) return -1;
            if (edge) {
                const int root_a = find_root(parent, vertex), root_b = find_root(parent, neighbor);
                if (root_a == root_b) return -1;
                parent[root_a] = root_b;
            }
        }
    }

    int colors[kMaxVertices], queue[kMaxVertices];
    bool visited[kMaxVertices]{};
    for (int i = 0; i < n; ++i) colors[i] = 1;
    int maximum_color = 1;
    for (int start = 0; start < n; ++start) {
        if (visited[start]) continue;
        int head = 0, tail = 0;
        visited[start] = true;
        queue[tail++] = start;
        while (head < tail) {
            const int vertex = queue[head++];
            for (int neighbor = 0; neighbor < n; ++neighbor) {
                if ((masks[vertex] & (1u << neighbor)) == 0) continue;
                if (colors[vertex] == colors[neighbor]) ++colors[neighbor];
                if (colors[vertex] > maximum_color) maximum_color = colors[vertex];
                if (colors[neighbor] > maximum_color) maximum_color = colors[neighbor];
                if (maximum_color > colors_value) return 0;
                if (!visited[neighbor]) {
                    visited[neighbor] = true;
                    queue[tail++] = neighbor;
                }
            }
        }
    }
    return 1;
}
