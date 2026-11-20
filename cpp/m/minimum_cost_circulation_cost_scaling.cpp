#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 8;
constexpr std::size_t kMaxEdges = 10;
constexpr std::size_t kMaxArcs = 2 * kMaxEdges;
constexpr std::size_t kMaxInputLength = 43;
constexpr std::int64_t kCostOffset = 81;

struct ResidualArc {
    std::size_t from;
    std::size_t to;
    std::size_t reverse;
    std::int64_t capacity;
    std::int64_t cost;
};
} // namespace

extern "C" std::int64_t minimum_cost_circulation_cost_scaling(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxVertices)
        || input[1] < 0 || input[1] > static_cast<std::int64_t>(kMaxEdges)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 4 * m) return -1;

    std::array<ResidualArc, kMaxArcs> edges{};
    std::int64_t max_scaled_cost = 0;
    for (std::size_t index = 0; index < m; ++index) {
        const auto offset = 2 + 4 * index;
        const auto from_value = input[offset];
        const auto to_value = input[offset + 1];
        const auto capacity = input[offset + 2];
        const auto cost = input[offset + 3];
        if (from_value < 0 || from_value >= static_cast<std::int64_t>(n)
            || to_value < 0 || to_value >= static_cast<std::int64_t>(n)
            || capacity < 0 || capacity > 2 || cost < -4 || cost > 4) return -1;
        const auto from = static_cast<std::size_t>(from_value);
        const auto to = static_cast<std::size_t>(to_value);
        const auto scaled_cost = cost * static_cast<std::int64_t>(n + 1);
        const auto forward = 2 * index;
        const auto reverse = forward + 1;
        edges[forward] = {from, to, reverse, capacity, scaled_cost};
        edges[reverse] = {to, from, forward, 0, -scaled_cost};
        const auto magnitude = scaled_cost < 0 ? -scaled_cost : scaled_cost;
        if (magnitude > max_scaled_cost) max_scaled_cost = magnitude;
    }

    std::int64_t epsilon = 1;
    while (epsilon < max_scaled_cost) epsilon *= 2;
    std::array<std::int64_t, kMaxVertices> price{};
    const auto arc_count = 2 * m;
    while (epsilon > 1) {
        epsilon /= 2;
        std::array<std::int64_t, kMaxVertices> excess{};

        for (std::size_t edge_index = 0; edge_index < arc_count; ++edge_index) {
            if (edges[edge_index].capacity <= 0) continue;
            const auto from = edges[edge_index].from;
            const auto to = edges[edge_index].to;
            const auto reduced_cost = edges[edge_index].cost + price[from] - price[to];
            if (reduced_cost < 0) {
                const auto amount = edges[edge_index].capacity;
                edges[edge_index].capacity = 0;
                edges[edges[edge_index].reverse].capacity += amount;
                excess[from] -= amount;
                excess[to] += amount;
            }
        }

        std::array<std::size_t, kMaxVertices> queue{};
        std::array<bool, kMaxVertices> queued{};
        std::size_t head = 0;
        std::size_t tail = 0;
        std::size_t queue_count = 0;
        for (std::size_t vertex = 0; vertex < n; ++vertex) {
            if (excess[vertex] > 0) {
                queue[tail] = vertex;
                tail = (tail + 1) % n;
                ++queue_count;
                queued[vertex] = true;
            }
        }

        while (queue_count > 0) {
            const auto vertex = queue[head];
            head = (head + 1) % n;
            --queue_count;
            queued[vertex] = false;
            while (excess[vertex] > 0) {
                auto admissible = kMaxArcs;
                for (std::size_t edge_index = 0; edge_index < arc_count; ++edge_index) {
                    const auto edge = edges[edge_index];
                    if (edge.from != vertex || edge.to == vertex || edge.capacity <= 0) continue;
                    if (edge.cost + price[vertex] - price[edge.to] < 0) {
                        admissible = edge_index;
                        break;
                    }
                }

                if (admissible < kMaxArcs) {
                    const auto to = edges[admissible].to;
                    const auto reverse = edges[admissible].reverse;
                    const auto amount = excess[vertex] < edges[admissible].capacity
                        ? excess[vertex] : edges[admissible].capacity;
                    edges[admissible].capacity -= amount;
                    edges[reverse].capacity += amount;
                    const auto old_excess = excess[to];
                    excess[vertex] -= amount;
                    excess[to] += amount;
                    if (old_excess <= 0 && excess[to] > 0 && !queued[to]) {
                        queue[tail] = to;
                        tail = (tail + 1) % n;
                        ++queue_count;
                        queued[to] = true;
                    }
                } else {
                    bool has_exit = false;
                    std::int64_t best_price = 0;
                    for (std::size_t edge_index = 0; edge_index < arc_count; ++edge_index) {
                        const auto edge = edges[edge_index];
                        if (edge.from != vertex || edge.capacity <= 0) continue;
                        const auto candidate = price[edge.to] - edge.cost - epsilon;
                        if (!has_exit || candidate > best_price) {
                            has_exit = true;
                            best_price = candidate;
                        }
                    }
                    if (!has_exit) return -1;
                    price[vertex] = best_price;
                }
            }
        }
        for (std::size_t vertex = 0; vertex < n; ++vertex) {
            if (excess[vertex] != 0) return -1;
        }
    }

    std::int64_t total_cost = 0;
    for (std::size_t index = 0; index < m; ++index) {
        const auto capacity = input[2 + 4 * index + 2];
        const auto cost = input[2 + 4 * index + 3];
        const auto flow = capacity - edges[2 * index].capacity;
        total_cost += flow * cost;
    }
    return total_cost + kCostOffset;
}
