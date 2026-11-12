#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxVertices = 8;
constexpr int kMaxEdges = 24;
constexpr std::int64_t kFlowInfinity = 2401;
constexpr std::size_t kMaxInputValues = 4 + 3 * kMaxEdges + 1;

std::int64_t push_forward(int vertex, int sink, std::int64_t amount, int n,
    std::array<std::int64_t, kMaxVertices * kMaxVertices> &residual,
    std::array<std::uint8_t, kMaxVertices * kMaxVertices> &active,
    std::array<std::int64_t, kMaxVertices> &incoming,
    std::array<std::int64_t, kMaxVertices> &outgoing) {
    if (vertex == sink) return amount;
    auto remaining = amount;
    for (int next = 0; next < n && remaining > 0; ++next) {
        const int edge = vertex * kMaxVertices + next;
        if (!active[edge] || residual[edge] == 0) continue;
        const auto pushed = push_forward(next, sink, std::min(remaining, residual[edge]),
            n, residual, active, incoming, outgoing);
        if (pushed == 0) continue;
        residual[edge] -= pushed;
        residual[next * kMaxVertices + vertex] += pushed;
        outgoing[vertex] -= pushed;
        incoming[next] -= pushed;
        remaining -= pushed;
        if (residual[edge] == 0) active[edge] = 0;
    }
    return amount - remaining;
}

std::int64_t push_backward(int vertex, int source, std::int64_t amount, int n,
    std::array<std::int64_t, kMaxVertices * kMaxVertices> &residual,
    std::array<std::uint8_t, kMaxVertices * kMaxVertices> &active,
    std::array<std::int64_t, kMaxVertices> &incoming,
    std::array<std::int64_t, kMaxVertices> &outgoing) {
    if (vertex == source) return amount;
    auto remaining = amount;
    for (int previous = 0; previous < n && remaining > 0; ++previous) {
        const int edge = previous * kMaxVertices + vertex;
        if (!active[edge] || residual[edge] == 0) continue;
        const auto pushed = push_backward(previous, source, std::min(remaining, residual[edge]),
            n, residual, active, incoming, outgoing);
        if (pushed == 0) continue;
        residual[edge] -= pushed;
        residual[vertex * kMaxVertices + previous] += pushed;
        incoming[vertex] -= pushed;
        outgoing[previous] -= pushed;
        remaining -= pushed;
        if (residual[edge] == 0) active[edge] = 0;
    }
    return amount - remaining;
}

void remove_vertex(int vertex, int n,
    std::array<std::int64_t, kMaxVertices * kMaxVertices> &residual,
    std::array<std::uint8_t, kMaxVertices * kMaxVertices> &active,
    std::array<std::int64_t, kMaxVertices> &incoming,
    std::array<std::int64_t, kMaxVertices> &outgoing,
    std::array<std::uint8_t, kMaxVertices> &alive) {
    for (int other = 0; other < n; ++other) {
        const int in_edge = other * kMaxVertices + vertex;
        if (active[in_edge]) {
            const auto capacity = residual[in_edge];
            outgoing[other] -= capacity;
            incoming[vertex] -= capacity;
            active[in_edge] = 0;
        }
        const int out_edge = vertex * kMaxVertices + other;
        if (active[out_edge]) {
            const auto capacity = residual[out_edge];
            outgoing[vertex] -= capacity;
            incoming[other] -= capacity;
            active[out_edge] = 0;
        }
    }
    alive[vertex] = 0;
}
}

extern "C" std::int64_t mpm_maxflow(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 4 || length > kMaxInputValues) return -1;
    const auto n_value = input[0], edge_count_value = input[1];
    const auto source_value = input[2], sink_value = input[3];
    if (n_value < 2 || n_value > kMaxVertices || edge_count_value < 0 ||
        edge_count_value > kMaxEdges || source_value < 1 || source_value > n_value ||
        sink_value < 1 || sink_value > n_value || source_value == sink_value) return -1;
    const int n = static_cast<int>(n_value), edge_count = static_cast<int>(edge_count_value);
    const int source = static_cast<int>(source_value - 1), sink = static_cast<int>(sink_value - 1);
    if (length != static_cast<std::size_t>(4 + 3 * edge_count)) return -1;

    std::array<std::int64_t, kMaxVertices * kMaxVertices> residual{};
    for (int edge = 0; edge < edge_count; ++edge) {
        const auto from_value = input[4 + 3 * edge];
        const auto to_value = input[5 + 3 * edge];
        const auto capacity = input[6 + 3 * edge];
        if (from_value < 1 || from_value > n_value || to_value < 1 || to_value > n_value ||
            from_value == to_value || capacity < 0 || capacity > 100) return -1;
        residual[(from_value - 1) * kMaxVertices + to_value - 1] += capacity;
    }

    std::int64_t total_flow = 0;
    for (;;) {
        std::array<int, kMaxVertices> level{};
        level.fill(-1);
        std::array<int, kMaxVertices> queue{};
        int head = 0, tail = 0;
        level[source] = 0;
        queue[tail++] = source;
        while (head < tail) {
            const int vertex = queue[head++];
            for (int next = 0; next < n; ++next) {
                if (residual[vertex * kMaxVertices + next] > 0 && level[next] < 0) {
                    level[next] = level[vertex] + 1;
                    queue[tail++] = next;
                }
            }
        }
        if (level[sink] < 0) break;

        std::array<std::int64_t, kMaxVertices> incoming{}, outgoing{};
        std::array<std::uint8_t, kMaxVertices * kMaxVertices> active{};
        std::array<std::uint8_t, kMaxVertices> alive{};
        for (int vertex = 0; vertex < n; ++vertex)
            alive[vertex] = level[vertex] >= 0 && level[vertex] <= level[sink];
        for (int from = 0; from < n; ++from) {
            for (int to = 0; to < n; ++to) {
                const int edge = from * kMaxVertices + to;
                if (level[from] >= 0 && level[from] < level[sink] &&
                    level[to] == level[from] + 1 && residual[edge] > 0) {
                    active[edge] = 1;
                    outgoing[from] += residual[edge];
                    incoming[to] += residual[edge];
                }
            }
        }
        incoming[source] = kFlowInfinity;
        outgoing[sink] = kFlowInfinity;

        for (;;) {
            int reference = -1;
            auto least_potential = kFlowInfinity + 1;
            for (int vertex = 0; vertex < n; ++vertex) {
                if (!alive[vertex]) continue;
                const auto potential = std::min(incoming[vertex], outgoing[vertex]);
                if (potential < least_potential) {
                    least_potential = potential;
                    reference = vertex;
                }
            }
            if (reference < 0) break;
            if (least_potential > 0) {
                total_flow += least_potential;
                (void)push_backward(reference, source, least_potential, n,
                    residual, active, incoming, outgoing);
                (void)push_forward(reference, sink, least_potential, n,
                    residual, active, incoming, outgoing);
            }
            remove_vertex(reference, n, residual, active, incoming, outgoing, alive);
        }
    }
    return total_flow;
}
