#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 16, EDGES = 120, INPUT = 242, OUTPUT = 2064;
void put(std::uint8_t *out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (int i = 0; i < 8; ++i) { out[at + i] = static_cast<std::uint8_t>(bits); bits >>= 8; }
}
}

extern "C" std::int64_t treewidth_min_fill_elimination(
    const std::int64_t *v, std::size_t length, std::uint8_t *out, std::size_t capacity) {
    if (!v || length < 2 || length > INPUT || v[0] < 1 || v[0] > N || v[1] < 0 || v[1] > EDGES) return -1;
    const int n = static_cast<int>(v[0]), m = static_cast<int>(v[1]);
    if (m > n * (n - 1) / 2 || length != static_cast<std::size_t>(2 + 2 * m)) return -1;
    bool adjacent[N][N]{};
    for (int edge = 0; edge < m; ++edge) {
        const auto a0 = v[2 + 2 * edge], b0 = v[3 + 2 * edge];
        if (a0 < 0 || b0 < 0 || a0 >= n || b0 >= n || a0 >= b0 || adjacent[a0][b0]) return -1;
        adjacent[a0][b0] = adjacent[b0][a0] = true;
    }
    bool active[N]{};
    std::int64_t order[N]{}, fill_u[EDGES]{}, fill_v[EDGES]{};
    for (int i = 0; i < n; ++i) active[i] = true;
    int width = 0, fill_count = 0;
    for (int step = 0; step < n; ++step) {
        int chosen = -1, chosen_fill = EDGES + 1, chosen_degree = 0;
        for (int vertex = 0; vertex < n; ++vertex) if (active[vertex]) {
            int neighbors[N], count = 0;
            for (int other = 0; other < n; ++other) if (active[other] && adjacent[vertex][other]) neighbors[count++] = other;
            int fill = 0;
            for (int i = 0; i < count; ++i) for (int j = i + 1; j < count; ++j) fill += !adjacent[neighbors[i]][neighbors[j]];
            if (fill < chosen_fill) { chosen = vertex; chosen_fill = fill; chosen_degree = count; }
        }
        order[step] = chosen;
        if (chosen_degree > width) width = chosen_degree;
        int neighbors[N], count = 0;
        for (int other = 0; other < n; ++other) if (active[other] && adjacent[chosen][other]) neighbors[count++] = other;
        for (int i = 0; i < count; ++i) for (int j = i + 1; j < count; ++j) {
            const int a = neighbors[i], b = neighbors[j];
            if (!adjacent[a][b]) { adjacent[a][b] = adjacent[b][a] = true; fill_u[fill_count] = a; fill_v[fill_count] = b; ++fill_count; }
        }
        active[chosen] = false;
    }
    const std::size_t bytes = 8 * (static_cast<std::size_t>(n) + 2 + 2 * static_cast<std::size_t>(fill_count));
    std::uint8_t staged[OUTPUT]{};
    put(staged, 0, width);
    for (int i = 0; i < n; ++i) put(staged, 8 * static_cast<std::size_t>(i + 1), order[i]);
    put(staged, 8 * static_cast<std::size_t>(n + 1), fill_count);
    for (int i = 0; i < fill_count; ++i) {
        put(staged, 8 * static_cast<std::size_t>(n + 2 + 2 * i), fill_u[i]);
        put(staged, 8 * static_cast<std::size_t>(n + 3 + 2 * i), fill_v[i]);
    }
    if (!out || capacity < bytes) return -2;
    for (std::size_t i = 0; i < bytes; ++i) out[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
