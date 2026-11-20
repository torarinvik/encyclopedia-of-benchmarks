/* Clean-room LDFS+ / Rightmost-Neighbor path-cover profile. */
#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr int max_n = 8;
constexpr std::size_t max_parseable = 18;

int compare_label(const std::array<std::uint8_t, max_n>& a, int a_size,
                  const std::array<std::uint8_t, max_n>& b, int b_size) {
    const int common = a_size < b_size ? a_size : b_size;
    for (int i = 0; i < common; ++i) {
        if (a[static_cast<std::size_t>(i)] != b[static_cast<std::size_t>(i)])
            return a[static_cast<std::size_t>(i)] > b[static_cast<std::size_t>(i)] ? 1 : -1;
    }
    return (a_size > b_size) - (a_size < b_size);
}
}

extern "C" std::int64_t cocomparability_ldfs_minimum_path_cover(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1 || length > max_parseable) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 1 || n_value > max_n || length != 1 + 2 * static_cast<std::size_t>(n_value)) return -1;
    const int n = static_cast<int>(n_value);
    const std::uint16_t full = static_cast<std::uint16_t>((1u << n) - 1u);
    std::array<std::uint16_t, max_n> adjacency{};
    std::array<int, max_n> order{}, rank{}, position{};
    std::array<bool, max_n> seen_order{};
    for (int v = 0; v < n; ++v) {
        const std::int64_t row = input[1 + v];
        if (row < 0 || static_cast<std::uint64_t>(row) > full ||
            (row & (std::int64_t{1} << v)) != 0) return -1;
        adjacency[static_cast<std::size_t>(v)] = static_cast<std::uint16_t>(row);
    }
    for (int u = 0; u < n; ++u)
        for (int v = 0; v < n; ++v)
            if (((adjacency[u] >> v) & 1u) != ((adjacency[v] >> u) & 1u)) return -1;
    for (int i = 0; i < n; ++i) {
        const std::int64_t value = input[1 + n + i];
        if (value < 0 || value >= n || seen_order[static_cast<std::size_t>(value)]) return -1;
        order[static_cast<std::size_t>(i)] = static_cast<int>(value);
        rank[static_cast<std::size_t>(value)] = i;
        seen_order[static_cast<std::size_t>(value)] = true;
    }
    for (int i = 0; i < n; ++i)
        for (int j = i + 1; j < n; ++j)
            for (int k = j + 1; k < n; ++k) {
                const int a = order[i], b = order[j], c = order[k];
                if (((adjacency[a] >> c) & 1u) &&
                    !(((adjacency[a] >> b) & 1u) || ((adjacency[b] >> c) & 1u))) return -1;
            }

    std::array<bool, max_n> reached{};
    std::vector<int> queue{0};
    reached[0] = true;
    for (std::size_t head = 0; head < queue.size(); ++head) {
        const int u = queue[head];
        for (int v = 0; v < n; ++v) {
            if (((adjacency[u] >> v) & 1u) && !reached[v]) {
                reached[v] = true;
                queue.push_back(v);
            }
        }
    }
    for (int v = 0; v < n; ++v) if (!reached[v]) return -1;

    std::array<std::array<std::uint8_t, max_n>, max_n> labels{};
    std::array<int, max_n> label_size{};
    std::array<bool, max_n> visited{};
    std::array<int, max_n> ldfs{};
    for (int step = 1; step <= n; ++step) {
        int chosen = -1;
        for (int v = 0; v < n; ++v) if (!visited[v]) {
            if (chosen < 0) chosen = v;
            else {
                const int cmp = compare_label(labels[v], label_size[v], labels[chosen], label_size[chosen]);
                if (cmp > 0 || (cmp == 0 && rank[v] > rank[chosen])) chosen = v;
            }
        }
        ldfs[static_cast<std::size_t>(step - 1)] = chosen;
        visited[static_cast<std::size_t>(chosen)] = true;
        for (int v = 0; v < n; ++v) if (!visited[v] && ((adjacency[chosen] >> v) & 1u)) {
            for (int i = label_size[v]; i > 0; --i)
                labels[v][static_cast<std::size_t>(i)] = labels[v][static_cast<std::size_t>(i - 1)];
            labels[v][0] = static_cast<std::uint8_t>(step);
            ++label_size[v];
        }
    }
    for (int i = 0; i < n; ++i) position[static_cast<std::size_t>(ldfs[i])] = i;

    visited.fill(false);
    int paths = 0;
    while (true) {
        int current = -1;
        for (int v = 0; v < n; ++v)
            if (!visited[v] && (current < 0 || position[v] > position[current])) current = v;
        if (current < 0) break;
        ++paths;
        visited[static_cast<std::size_t>(current)] = true;
        while (true) {
            int next = -1;
            for (int v = 0; v < n; ++v)
                if (!visited[v] && ((adjacency[current] >> v) & 1u) &&
                    (next < 0 || position[v] > position[next])) next = v;
            if (next < 0) break;
            visited[static_cast<std::size_t>(next)] = true;
            current = next;
        }
    }
    return paths;
}
