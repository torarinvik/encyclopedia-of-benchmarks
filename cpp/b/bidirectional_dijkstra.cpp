/* Shortest distance in a bounded directed graph using two Dijkstra frontiers. */
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t MAX_VERTICES = 64;
constexpr std::size_t MAX_EDGES = 256;
constexpr std::int64_t MAX_WEIGHT = 1'000'000;
}

extern "C" std::int64_t bidirectional_dijkstra(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4) return -1;
    const auto n_value = input[0], m_value = input[1];
    const auto source_value = input[2], target_value = input[3];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(MAX_VERTICES)
            || m_value < 0 || m_value > static_cast<std::int64_t>(MAX_EDGES)) return -1;
    const auto n = static_cast<std::size_t>(n_value), m = static_cast<std::size_t>(m_value);
    if (source_value < 0 || source_value >= n_value || target_value < 0 || target_value >= n_value) return -1;
    if (length != 4 + 3 * m) return -1;
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto from = input[4 + 3 * edge], to = input[5 + 3 * edge], weight = input[6 + 3 * edge];
        if (from < 0 || from >= n_value || to < 0 || to >= n_value || weight < 0 || weight > MAX_WEIGHT)
            return -1;
    }
    const auto source = static_cast<std::size_t>(source_value), target = static_cast<std::size_t>(target_value);
    if (source == target) return 0;

    const auto inf = std::numeric_limits<std::int64_t>::max();
    std::int64_t forward[MAX_VERTICES], backward[MAX_VERTICES];
    bool settled_forward[MAX_VERTICES]{}, settled_backward[MAX_VERTICES]{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) forward[vertex] = backward[vertex] = inf;
    forward[source] = 0;
    backward[target] = 0;
    auto best = inf;

    for (std::size_t step = 0; step < 2 * n; ++step) {
        std::size_t next_forward = n, next_backward = n;
        auto min_forward = inf, min_backward = inf;
        for (std::size_t vertex = 0; vertex < n; ++vertex) {
            if (!settled_forward[vertex] && forward[vertex] < min_forward) {
                min_forward = forward[vertex];
                next_forward = vertex;
            }
            if (!settled_backward[vertex] && backward[vertex] < min_backward) {
                min_backward = backward[vertex];
                next_backward = vertex;
            }
        }
        if (next_forward == n || next_backward == n) break;
        if (best != inf && min_forward + min_backward >= best) break;

        if (min_forward <= min_backward) {
            const auto current = next_forward;
            settled_forward[current] = true;
            if (backward[current] != inf && forward[current] + backward[current] < best)
                best = forward[current] + backward[current];
            for (std::size_t edge = 0; edge < m; ++edge) {
                if (static_cast<std::size_t>(input[4 + 3 * edge]) != current) continue;
                const auto to = static_cast<std::size_t>(input[5 + 3 * edge]);
                const auto candidate = forward[current] + input[6 + 3 * edge];
                if (!settled_forward[to] && candidate < forward[to]) forward[to] = candidate;
                if (backward[to] != inf && candidate + backward[to] < best) best = candidate + backward[to];
            }
        } else {
            const auto current = next_backward;
            settled_backward[current] = true;
            if (forward[current] != inf && forward[current] + backward[current] < best)
                best = forward[current] + backward[current];
            for (std::size_t edge = 0; edge < m; ++edge) {
                if (static_cast<std::size_t>(input[5 + 3 * edge]) != current) continue;
                const auto from = static_cast<std::size_t>(input[4 + 3 * edge]);
                const auto candidate = backward[current] + input[6 + 3 * edge];
                if (!settled_backward[from] && candidate < backward[from]) backward[from] = candidate;
                if (forward[from] != inf) {
                    const auto through_edge = forward[from] + input[6 + 3 * edge] + backward[current];
                    if (through_edge < best) best = through_edge;
                }
            }
        }
    }
    return best == inf ? -1 : best;
}
