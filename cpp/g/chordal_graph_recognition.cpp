#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 6;
constexpr std::size_t MAX_INPUT = 32, MAX_OUTPUT_VALUES = 8, MAX_OUTPUT_BYTES = 64;
using Graph = std::array<std::array<bool, N>, N>;

void put_u64(std::array<std::uint8_t, MAX_OUTPUT_BYTES>& out, std::size_t index, std::uint64_t value) {
    for (std::size_t byte = 0; byte < 8; ++byte) out[index * 8 + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}

bool induced_cycle(const Graph& adjacent, int n, std::array<int, N>& cycle, int& length) {
    for (unsigned mask = 0; mask < (1u << n); ++mask) {
        std::array<int, N> vertices{};
        int count = 0;
        for (int v = 0; v < n; ++v) if (mask & (1u << v)) vertices[count++] = v;
        if (count < 4) continue;
        bool valid = true;
        for (int i = 0; i < count; ++i) {
            int degree = 0;
            for (int j = 0; j < count; ++j) degree += adjacent[vertices[i]][vertices[j]];
            if (degree != 2) valid = false;
        }
        if (!valid) continue;
        std::array<bool, N> seen{};
        std::array<int, N> queue{};
        int head = 0, tail = 0;
        seen[vertices[0]] = true; queue[tail++] = vertices[0];
        while (head < tail) {
            const int v = queue[head++];
            for (int i = 0; i < count; ++i) {
                const int u = vertices[i];
                if (adjacent[v][u] && !seen[u]) { seen[u] = true; queue[tail++] = u; }
            }
        }
        if (tail != count) continue;
        const int start = vertices[0];
        int previous = start, current = -1;
        for (int i = 0; i < count; ++i) if (adjacent[start][vertices[i]]) { current = vertices[i]; break; }
        cycle[0] = start;
        for (int i = 1; i < count; ++i) {
            cycle[i] = current;
            int next = -1;
            for (int j = 0; j < count; ++j)
                if (adjacent[current][vertices[j]] && vertices[j] != previous) { next = vertices[j]; break; }
            previous = current; current = next;
        }
        length = count;
        return true;
    }
    return false;
}
}

extern "C" std::int64_t chordal_graph_recognition(const std::int64_t* input, std::size_t length,
                                                    std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > MAX_INPUT || input[0] < 1 || input[0] > N || input[1] < 0 || input[1] > 15) return -1;
    const int n = static_cast<int>(input[0]), m = static_cast<int>(input[1]);
    if (m > n * (n - 1) / 2 || length != static_cast<std::size_t>(2 + 2 * m)) return -1;
    Graph adjacent{};
    for (int e = 0; e < m; ++e) {
        const auto a0 = input[2 + 2 * e], b0 = input[3 + 2 * e];
        if (a0 < 0 || b0 < 0 || a0 >= n || b0 >= n || a0 == b0) return -1;
        const int a = static_cast<int>(a0), b = static_cast<int>(b0);
        if (adjacent[a][b]) return -1;
        adjacent[a][b] = adjacent[b][a] = true;
    }
    std::array<bool, N> selected{};
    std::array<int, N> label{}, reverse_order{}, order{}, position{};
    for (int step = 0; step < n; ++step) {
        int chosen = -1;
        for (int v = 0; v < n; ++v) if (!selected[v] && (chosen < 0 || label[v] > label[chosen])) chosen = v;
        selected[chosen] = true; reverse_order[step] = chosen;
        for (int u = 0; u < n; ++u) if (!selected[u] && adjacent[chosen][u]) ++label[u];
    }
    for (int i = 0; i < n; ++i) { order[i] = reverse_order[n - i - 1]; position[order[i]] = i; }
    bool peo = true;
    for (int i = 0; i < n && peo; ++i) {
        const int v = order[i];
        int parent = -1;
        for (int u = 0; u < n; ++u) if (adjacent[v][u] && position[u] > i && (parent < 0 || position[u] < position[parent])) parent = u;
        if (parent >= 0) for (int u = 0; u < n; ++u)
            if (adjacent[v][u] && position[u] > i && u != parent && !adjacent[parent][u]) peo = false;
    }
    std::array<std::uint64_t, MAX_OUTPUT_VALUES> packed{};
    std::size_t count = 0;
    if (peo) { packed[count++] = 1; for (int i = 0; i < n; ++i) packed[count++] = order[i]; }
    else {
        std::array<int, N> cycle{}; int cycle_length = 0;
        if (!induced_cycle(adjacent, n, cycle, cycle_length)) return -1;
        packed[count++] = 0; packed[count++] = cycle_length;
        for (int i = 0; i < cycle_length; ++i) packed[count++] = cycle[i];
    }
    const std::size_t bytes = count * 8;
    if (!output || capacity < bytes) return -2;
    std::array<std::uint8_t, MAX_OUTPUT_BYTES> staged{};
    for (std::size_t i = 0; i < count; ++i) put_u64(staged, i, packed[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
