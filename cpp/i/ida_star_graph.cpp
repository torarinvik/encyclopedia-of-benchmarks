#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
struct Search {
    int n{}, goal{}, bound{}, next{};
    std::array<int, 12> heuristic{};
    std::array<unsigned, 12> edges{};

    int visit(int vertex, int depth, unsigned path) {
        int score = depth + heuristic[vertex];
        if (score > bound) { if (score < next) next = score; return -1; }
        if (vertex == goal) return depth;
        for (int v = 0; v < n; ++v) {
            unsigned bit = 1u << v;
            if ((edges[vertex] & bit) && !(path & bit)) {
                int found = visit(v, depth + 1, path | bit);
                if (found >= 0) return found;
            }
        }
        return -1;
    }
};
}

extern "C" std::int64_t ida_star_graph(const std::int64_t *values, std::size_t length) {
    constexpr auto invalid = std::numeric_limits<std::int64_t>::min();
    if (!values || length < 5 || length > 112) return invalid;
    auto n = values[0], m = values[1], start = values[2], goal = values[3];
    if (n < 1 || n > 12 || m < 0 || m > 48 || start < 0 || start >= n ||
        goal < 0 || goal >= n || length != static_cast<std::size_t>(4+n+2*m)) return invalid;
    Search s;
    s.n = static_cast<int>(n); s.goal = static_cast<int>(goal);
    for (int i = 0; i < n; ++i) {
        if (values[4+i] < 0 || values[4+i] >= n) return invalid;
        s.heuristic[i] = static_cast<int>(values[4+i]);
    }
    if (s.heuristic[goal] != 0) return invalid;
    for (int i = 0; i < m; ++i) {
        auto u = values[4+n+2*i], v = values[5+n+2*i];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v ||
            (s.edges[u] & (1u << v)) || s.heuristic[u] > s.heuristic[v] + 1) return invalid;
        s.edges[u] |= 1u << v;
    }
    s.bound = s.heuristic[start];
    for (;;) {
        s.next = 1000;
        int result = s.visit(static_cast<int>(start), 0, 1u << start);
        if (result >= 0) return result;
        if (s.next == 1000) return -1;
        s.bound = s.next;
    }
}
