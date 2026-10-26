#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 8, EDGES = 28, INPUT = 58, OUTPUT = 72;
void put(std::uint8_t *out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (int i = 0; i < 8; ++i) { out[at + i] = static_cast<std::uint8_t>(bits); bits >>= 8; }
}
}

extern "C" std::int64_t treewidth_exact_elimination_order(const std::int64_t *v, std::size_t length,
    std::uint8_t *out, std::size_t capacity) {
    if (!v || length < 2 || length > INPUT || v[0] < 1 || v[0] > N || v[1] < 0 || v[1] > EDGES) return -1;
    const int n = static_cast<int>(v[0]), m = static_cast<int>(v[1]);
    if (m > n * (n - 1) / 2 || length != static_cast<std::size_t>(2 + 2 * m)) return -1;
    bool base[N * N]{};
    for (int e = 0; e < m; ++e) {
        const auto a0 = v[2 + 2 * e], b0 = v[3 + 2 * e];
        if (a0 < 0 || b0 < 0 || a0 >= n || b0 >= n || a0 >= b0) return -1;
        const int a = static_cast<int>(a0), b = static_cast<int>(b0);
        if (base[a * N + b]) return -1;
        base[a * N + b] = base[b * N + a] = true;
    }
    int permutation[N]{}, best_order[N]{};
    for (int i = 0; i < n; ++i) permutation[i] = i;
    int best_width = N + 1;
    for (;;) {
        bool adjacent[N * N]{}; bool active[N]{};
        for (int i = 0; i < N * N; ++i) adjacent[i] = base[i];
        for (int i = 0; i < n; ++i) active[i] = true;
        int width = 0;
        for (int step = 0; step < n; ++step) {
            const int vertex = permutation[step];
            int neighbors[N], count = 0;
            for (int other = 0; other < n; ++other) if (active[other] && adjacent[vertex * N + other]) neighbors[count++] = other;
            if (count > width) width = count;
            for (int i = 0; i < count; ++i) for (int j = i + 1; j < count; ++j) {
                const int a = neighbors[i], b = neighbors[j]; adjacent[a * N + b] = adjacent[b * N + a] = true;
            }
            active[vertex] = false;
        }
        if (width < best_width) { best_width = width; for (int i = 0; i < n; ++i) best_order[i] = permutation[i]; }
        int pivot = n - 2;
        while (pivot >= 0 && permutation[pivot] >= permutation[pivot + 1]) --pivot;
        if (pivot < 0) break;
        int successor = n - 1;
        while (permutation[successor] <= permutation[pivot]) --successor;
        int temp = permutation[pivot]; permutation[pivot] = permutation[successor]; permutation[successor] = temp;
        for (int left = pivot + 1, right = n - 1; left < right; ++left, --right) {
            temp = permutation[left]; permutation[left] = permutation[right]; permutation[right] = temp;
        }
    }
    const std::size_t bytes = 8 * static_cast<std::size_t>(n + 1);
    std::uint8_t staged[OUTPUT]{}; put(staged, 0, best_width);
    for (int i = 0; i < n; ++i) put(staged, 8 * static_cast<std::size_t>(i + 1), best_order[i]);
    if (!out || capacity < bytes) return -2;
    for (std::size_t i = 0; i < bytes; ++i) out[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
