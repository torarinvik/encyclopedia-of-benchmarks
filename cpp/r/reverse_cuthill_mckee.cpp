#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 8;
constexpr std::size_t kMaxEdges = 28;
constexpr std::size_t kMaxInputLength = 59;

bool neighbor_precedes(int left, int right, const int* degree) noexcept {
    return degree[left] != degree[right] ? degree[left] < degree[right] : left < right;
}
}  // namespace

extern "C" std::int64_t reverse_cuthill_mckee(const std::int64_t* input,
                                                std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const auto n64 = input[0];
    const auto m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(kMaxVertices) ||
        m64 < 0 || m64 > static_cast<std::int64_t>(kMaxEdges)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    const auto m = static_cast<std::size_t>(m64);
    if (m > n * (n - 1) / 2 || length != 2 + 2 * m) return -1;

    bool adjacent[kMaxVertices][kMaxVertices]{};
    int degree[kMaxVertices]{};
    std::size_t edge_u[kMaxEdges]{}, edge_v[kMaxEdges]{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto left64 = input[2 + 2 * edge];
        const auto right64 = input[3 + 2 * edge];
        if (left64 < 0 || right64 < 0 || left64 >= static_cast<std::int64_t>(n) ||
            right64 >= static_cast<std::int64_t>(n) || left64 == right64) return -1;
        const auto left = static_cast<std::size_t>(left64);
        const auto right = static_cast<std::size_t>(right64);
        if (adjacent[left][right]) return -1;
        adjacent[left][right] = adjacent[right][left] = true;
        ++degree[left];
        ++degree[right];
        edge_u[edge] = left;
        edge_v[edge] = right;
    }

    bool visited[kMaxVertices]{};
    int order[kMaxVertices]{};
    std::size_t order_count = 0;
    while (order_count < n) {
        int root = -1;
        for (std::size_t vertex = 0; vertex < n; ++vertex) {
            const int id = static_cast<int>(vertex);
            if (!visited[vertex] &&
                (root < 0 || degree[id] < degree[root] ||
                 (degree[id] == degree[root] && id < root))) root = id;
        }
        int queue[kMaxVertices]{};
        std::size_t head = 0, tail = 0;
        visited[static_cast<std::size_t>(root)] = true;
        queue[tail++] = root;
        order[order_count++] = root;
        while (head < tail) {
            const int vertex = queue[head++];
            int neighbors[kMaxVertices]{};
            std::size_t neighbor_count = 0;
            for (std::size_t neighbor = 0; neighbor < n; ++neighbor)
                if (adjacent[static_cast<std::size_t>(vertex)][neighbor] && !visited[neighbor])
                    neighbors[neighbor_count++] = static_cast<int>(neighbor);
            for (std::size_t i = 1; i < neighbor_count; ++i) {
                const int key = neighbors[i];
                auto j = i;
                while (j > 0 && neighbor_precedes(key, neighbors[j - 1], degree)) {
                    neighbors[j] = neighbors[j - 1];
                    --j;
                }
                neighbors[j] = key;
            }
            for (std::size_t i = 0; i < neighbor_count; ++i) {
                const int neighbor = neighbors[i];
                const auto neighbor_index = static_cast<std::size_t>(neighbor);
                if (visited[neighbor_index]) continue;
                visited[neighbor_index] = true;
                queue[tail++] = neighbor;
                order[order_count++] = neighbor;
            }
        }
    }

    for (std::size_t left = 0, right = n - 1; left < right; ++left, --right) {
        const int temporary = order[left];
        order[left] = order[right];
        order[right] = temporary;
    }
    int position[kMaxVertices]{};
    std::int64_t rank_word = 0;
    for (std::size_t rank = 0; rank < n; ++rank) {
        position[static_cast<std::size_t>(order[rank])] = static_cast<int>(rank);
        rank_word |= static_cast<std::int64_t>(order[rank]) << (3 * rank);
    }
    int bandwidth = 0;
    for (std::size_t edge = 0; edge < m; ++edge) {
        int difference = position[edge_u[edge]] - position[edge_v[edge]];
        if (difference < 0) difference = -difference;
        if (difference > bandwidth) bandwidth = difference;
    }
    return (static_cast<std::int64_t>(bandwidth) << 24) | rank_word;
}
