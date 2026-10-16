#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_VERTICES = 8;
constexpr int MAX_EDGES = 256;
constexpr int MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES;
constexpr int MAX_DEGREE = 2 * MAX_EDGES;
constexpr int MAX_ROUTE = MAX_EDGES + 1;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);
constexpr std::uint64_t LOW63_MASK = UINT64_C(0x7fffffffffffffff);
std::uint64_t hash_word(std::uint64_t hash, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (int byte = 0; byte < 8; ++byte) {
        hash = (hash ^ static_cast<std::uint8_t>(bits)) * FNV_PRIME;
        bits >>= 8;
    }
    return hash;
}
}

extern "C" std::int64_t hierholzer_algorithm(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > MAX_VERTICES || m64 < 0 || m64 > MAX_EDGES || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    int adjacency[MAX_VERTICES][MAX_DEGREE]{};
    int degree[MAX_VERTICES]{};
    for (int edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= n || v64 < 0 || v64 >= n) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        adjacency[u][degree[u]++] = v; adjacency[v][degree[v]++] = u;
    }
    int has_circuit = 1, start = -1;
    for (int v = 0; v < n; ++v) { if (degree[v] % 2 != 0) has_circuit = 0; if (start < 0 && degree[v] > 0) start = v; }
    if (has_circuit && start >= 0) {
        bool seen[MAX_VERTICES]{}; int stack[MAX_VERTICES], top = 0; seen[start] = true; stack[top++] = start;
        while (top > 0) { const int u = stack[--top]; for (int i = 0; i < degree[u]; ++i) { const int v = adjacency[u][i]; if (!seen[v]) { seen[v] = true; stack[top++] = v; } } }
        for (int v = 0; v < n; ++v) if (degree[v] > 0 && !seen[v]) has_circuit = 0;
    }
    int route[MAX_ROUTE], route_length = 0;
    if (has_circuit) {
        if (start < 0) { if (n > 0) route[route_length++] = 0; }
        else {
            bool used[MAX_VERTICES][MAX_DEGREE]{}; int head[MAX_VERTICES]{}; int pair_cursor[MAX_VERTICES][MAX_VERTICES]{};
            int path[MAX_ROUTE], path_size = 0; path[path_size++] = start;
            while (path_size > 0) {
                const int u = path[path_size - 1]; while (head[u] < degree[u] && used[u][head[u]]) ++head[u];
                if (head[u] < degree[u]) {
                    const int p = head[u]; used[u][p] = true; const int v = adjacency[u][p]; int q = pair_cursor[v][u];
                    while (q < degree[v] && (used[v][q] || adjacency[v][q] != u)) ++q;
                    if (q >= degree[v]) return -1; used[v][q] = true; pair_cursor[v][u] = q + 1; path[path_size++] = v;
                } else route[route_length++] = path[--path_size];
            }
            for (int l = 0, r = route_length - 1; l < r; ++l, --r) { const int t = route[l]; route[l] = route[r]; route[r] = t; }
        }
    }
    std::uint64_t hash = FNV_OFFSET; hash = hash_word(hash, has_circuit); hash = hash_word(hash, route_length);
    for (int i = 0; i < route_length; ++i) hash = hash_word(hash, route[i]);
    return static_cast<std::int64_t>(hash & LOW63_MASK);
}
