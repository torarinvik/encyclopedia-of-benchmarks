#include <array>
#include <cstddef>
#include <cstdint>

namespace {
int root(const std::array<int, 8>& parent, int vertex) {
    while (parent[vertex] != vertex) vertex = parent[vertex];
    return vertex;
}
}

extern "C" std::int64_t karger_contraction_trial(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > 57) return -1;
    if (input[0] < 2 || input[0] > 8 || input[1] < 1 || input[1] > 24) return -1;
    const int n = static_cast<int>(input[0]), m = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + 2 * m + n - 2)) return -1;
    std::array<int, 24> u{}, v{};
    std::array<int, 8> parent{};
    for (int i = 0; i < n; ++i) parent[i] = i;
    for (int i = 0; i < m; ++i) {
        const auto a = input[2 + 2 * i], b = input[3 + 2 * i];
        if (a < 0 || b < 0 || a >= n || b >= n || a == b) return -1;
        u[i] = static_cast<int>(a); v[i] = static_cast<int>(b);
        parent[root(parent, u[i])] = root(parent, v[i]);
    }
    const auto initial = root(parent, 0);
    for (int i = 1; i < n; ++i) if (root(parent, i) != initial) return -1;
    for (int i = 0; i < n; ++i) parent[i] = i;
    for (int step = 0; step < n - 2; ++step) {
        int live = 0;
        for (int i = 0; i < m; ++i) if (root(parent, u[i]) != root(parent, v[i])) ++live;
        auto rank = input[2 + 2 * m + step];
        if (rank < 0 || rank >= live) return -1;
        for (int i = 0; i < m; ++i) {
            const auto left = root(parent, u[i]), right = root(parent, v[i]);
            if (left == right) continue;
            if (rank == 0) { parent[left] = right; break; }
            --rank;
        }
    }
    int cut = 0;
    for (int i = 0; i < m; ++i) if (root(parent, u[i]) != root(parent, v[i])) ++cut;
    return cut;
}
