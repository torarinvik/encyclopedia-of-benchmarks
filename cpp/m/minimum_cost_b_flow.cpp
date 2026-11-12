#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr int kMaxVertices = 8;
constexpr int kMaxEdges = 10;
constexpr int kMaxArcs = 2 * kMaxEdges + 2 * kMaxVertices;
constexpr int kMaxNodes = kMaxVertices + 2;
constexpr std::size_t kMaxInputLength = 2 + kMaxVertices + 5 * kMaxEdges + 1;
constexpr std::size_t kMaxOutputWords = 2 + kMaxVertices + kMaxEdges;

struct ResidualGraph {
    std::array<int, kMaxArcs> from{};
    std::array<int, kMaxArcs> to{};
    std::array<int, kMaxArcs> reverse{};
    std::array<std::int64_t, kMaxArcs> capacity{};
    std::array<std::int64_t, kMaxArcs> cost{};
    int arc_count = 0;
    int original_arc_count = 0;

    int add_edge(int source, int target, std::int64_t cap, std::int64_t price) noexcept {
        const int forward = arc_count++;
        const int backward = arc_count++;
        from[forward] = source;
        to[forward] = target;
        reverse[forward] = backward;
        capacity[forward] = cap;
        cost[forward] = price;
        from[backward] = target;
        to[backward] = source;
        reverse[backward] = forward;
        capacity[backward] = 0;
        cost[backward] = -price;
        return forward;
    }

    bool feasible_flow(int vertex_count, std::int64_t required_flow) noexcept {
        const int super_source = vertex_count, super_sink = vertex_count + 1;
        std::int64_t sent = 0;
        while (sent < required_flow) {
            std::array<int, kMaxNodes> parent{};
            std::array<bool, kMaxNodes> seen{};
            std::array<int, kMaxNodes> queue{};
            parent.fill(-1);
            int head = 0, length = 0;
            seen[super_source] = true;
            queue[length++] = super_source;
            while (head < length) {
                const int vertex = queue[head++];
                for (int edge = 0; edge < arc_count; ++edge) {
                    const int neighbor = to[edge];
                    if (from[edge] == vertex && capacity[edge] > 0 && !seen[neighbor]) {
                        seen[neighbor] = true;
                        parent[neighbor] = edge;
                        queue[length++] = neighbor;
                    }
                }
            }
            if (!seen[super_sink]) return false;
            std::int64_t amount = required_flow - sent;
            for (int vertex = super_sink; vertex != super_source; vertex = from[parent[vertex]])
                amount = std::min(amount, capacity[parent[vertex]]);
            for (int vertex = super_sink; vertex != super_source; vertex = from[parent[vertex]]) {
                const int edge = parent[vertex];
                capacity[edge] -= amount;
                capacity[reverse[edge]] += amount;
            }
            sent += amount;
        }
        return true;
    }

    bool cancel_negative_cycles(int vertex_count) noexcept {
        if (vertex_count == 0) return true;
        for (;;) {
            std::array<std::int64_t, kMaxVertices> distance{};
            std::array<int, kMaxVertices> parent{};
            parent.fill(-1);
            int changed_vertex = -1;
            for (int pass = 0; pass < vertex_count; ++pass) {
                changed_vertex = -1;
                for (int edge = 0; edge < original_arc_count; ++edge) {
                    const int source = from[edge], target = to[edge];
                    if (capacity[edge] > 0 && distance[target] > distance[source] + cost[edge]) {
                        distance[target] = distance[source] + cost[edge];
                        parent[target] = edge;
                        changed_vertex = target;
                    }
                }
                if (changed_vertex == -1) break;
            }
            if (changed_vertex == -1) return true;
            int on_cycle = changed_vertex;
            for (int step = 0; step < vertex_count; ++step) {
                const int edge = parent[on_cycle];
                if (edge < 0) return false;
                on_cycle = from[edge];
            }
            std::int64_t amount = std::numeric_limits<std::int64_t>::max();
            int vertex = on_cycle;
            do {
                const int edge = parent[vertex];
                if (edge < 0) return false;
                amount = std::min(amount, capacity[edge]);
                vertex = from[edge];
            } while (vertex != on_cycle);
            vertex = on_cycle;
            do {
                const int edge = parent[vertex];
                capacity[edge] -= amount;
                capacity[reverse[edge]] += amount;
                vertex = from[edge];
            } while (vertex != on_cycle);
        }
    }
};

bool solve(int n, int m, const std::int64_t* input, std::array<std::int64_t, kMaxOutputWords>& words) noexcept {
    std::array<std::int64_t, kMaxVertices> required{};
    for (int vertex = 0; vertex < n; ++vertex) required[vertex] = input[2 + vertex];
    const std::size_t edge_offset = 2 + static_cast<std::size_t>(n);
    for (int edge = 0; edge < m; ++edge) {
        const std::size_t offset = edge_offset + 5 * static_cast<std::size_t>(edge);
        required[input[offset]] -= input[offset + 2];
        required[input[offset + 1]] += input[offset + 2];
    }
    std::int64_t sum = 0, required_flow = 0;
    for (int vertex = 0; vertex < n; ++vertex) {
        sum += required[vertex];
        if (required[vertex] > 0) required_flow += required[vertex];
    }
    if (sum != 0) return false;

    ResidualGraph graph{};
    for (int edge = 0; edge < m; ++edge) {
        const std::size_t offset = edge_offset + 5 * static_cast<std::size_t>(edge);
        graph.add_edge(static_cast<int>(input[offset]), static_cast<int>(input[offset + 1]),
                       input[offset + 3] - input[offset + 2], input[offset + 4]);
    }
    graph.original_arc_count = graph.arc_count;
    for (int vertex = 0; vertex < n; ++vertex) {
        if (required[vertex] > 0) graph.add_edge(n, vertex, required[vertex], 0);
        else if (required[vertex] < 0) graph.add_edge(vertex, n + 1, -required[vertex], 0);
    }
    if (!graph.feasible_flow(n, required_flow) || !graph.cancel_negative_cycles(n)) return false;

    std::array<std::int64_t, kMaxVertices> potential{};
    for (int pass = 0; pass < n - 1; ++pass) {
        bool changed = false;
        for (int edge = 0; edge < graph.original_arc_count; ++edge) {
            const int source = graph.from[edge], target = graph.to[edge];
            if (graph.capacity[edge] > 0 && potential[target] > potential[source] + graph.cost[edge]) {
                potential[target] = potential[source] + graph.cost[edge];
                changed = true;
            }
        }
        if (!changed) break;
    }
    words[0] = 1;
    words[1] = 0;
    for (int vertex = 0; vertex < n; ++vertex) words[2 + vertex] = potential[vertex];
    for (int edge = 0; edge < m; ++edge) {
        const std::size_t offset = edge_offset + 5 * static_cast<std::size_t>(edge);
        const auto flow = input[offset + 3] - graph.capacity[2 * edge];
        words[2 + n + edge] = flow;
        words[1] += flow * input[offset + 4];
    }
    return true;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>((bits >> (byte * 8)) & 0xffu);
}
} // namespace

extern "C" std::int64_t minimum_cost_b_flow(const std::int64_t* input, std::size_t length,
                                              std::uint8_t* output,
                                              std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const std::int64_t raw_n = input[0], raw_m = input[1];
    if (raw_n < 0 || raw_n > kMaxVertices || raw_m < 0 || raw_m > kMaxEdges) return -1;
    const int n = static_cast<int>(raw_n), m = static_cast<int>(raw_m);
    if (length != 2 + static_cast<std::size_t>(n) + 5 * static_cast<std::size_t>(m)) return -1;
    const std::size_t edge_offset = 2 + static_cast<std::size_t>(n);
    for (int vertex = 0; vertex < n; ++vertex)
        if (input[2 + vertex] < -5 || input[2 + vertex] > 5) return -1;
    for (int edge = 0; edge < m; ++edge) {
        const std::size_t offset = edge_offset + 5 * static_cast<std::size_t>(edge);
        const auto from = input[offset], to = input[offset + 1];
        const auto lower = input[offset + 2], upper = input[offset + 3], cost = input[offset + 4];
        if (from < 0 || from >= n || to < 0 || to >= n || lower < -3 || upper > 3 ||
            lower > upper || upper - lower > 2 || cost < -4 || cost > 4) return -1;
    }
    const std::size_t output_words = 2 + static_cast<std::size_t>(n) + static_cast<std::size_t>(m);
    const std::size_t output_bytes = 8 * output_words;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    std::array<std::int64_t, kMaxOutputWords> words{};
    if (!solve(n, m, input, words)) words.fill(0);
    for (std::size_t word = 0; word < output_words; ++word) store_i64_le(output, 8 * word, words[word]);
    return static_cast<std::int64_t>(output_bytes);
}
