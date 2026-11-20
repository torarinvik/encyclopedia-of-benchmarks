#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 6;
constexpr std::size_t max_m = 8;
constexpr std::size_t max_input = 37;
constexpr std::size_t node_cap = 8;
constexpr std::size_t matrix_cap = node_cap * node_cap;

bool feasible(const std::int64_t* input, std::size_t n, std::size_t m,
              std::size_t source, std::size_t sink, std::int64_t flow_cap) {
    std::array<std::int64_t, matrix_cap> residual{};
    std::array<std::int64_t, max_n> balance{};
    for (std::size_t i = 0; i < m; ++i) {
        const auto offset = 4 + 4 * i;
        const auto u = static_cast<std::size_t>(input[offset]);
        const auto v = static_cast<std::size_t>(input[offset + 1]);
        const auto lower = input[offset + 2];
        const auto upper = input[offset + 3];
        residual[u * node_cap + v] += upper - lower;
        balance[u] -= lower;
        balance[v] += lower;
    }
    residual[sink * node_cap + source] += flow_cap;

    const auto super_source = n;
    const auto super_sink = n + 1;
    const auto node_count = n + 2;
    std::int64_t demand = 0;
    for (std::size_t v = 0; v < n; ++v) {
        if (balance[v] > 0) {
            residual[super_source * node_cap + v] += balance[v];
            demand += balance[v];
        } else if (balance[v] < 0) {
            residual[v * node_cap + super_sink] += -balance[v];
        }
    }

    std::int64_t flow = 0;
    while (flow < demand) {
        std::array<int, node_cap> parent;
        parent.fill(-1);
        std::array<std::size_t, node_cap> queue{};
        std::size_t head = 0, tail = 0;
        parent[super_source] = static_cast<int>(super_source);
        queue[tail++] = super_source;
        while (head < tail && parent[super_sink] < 0) {
            const auto u = queue[head++];
            for (std::size_t v = 0; v < node_count; ++v) {
                if (residual[u * node_cap + v] > 0 && parent[v] < 0) {
                    parent[v] = static_cast<int>(u);
                    queue[tail++] = v;
                    if (v == super_sink) break;
                }
            }
        }
        if (parent[super_sink] < 0) break;
        auto amount = demand - flow;
        for (auto v = super_sink; v != super_source; v = static_cast<std::size_t>(parent[v])) {
            const auto u = static_cast<std::size_t>(parent[v]);
            amount = std::min(amount, residual[u * node_cap + v]);
        }
        for (auto v = super_sink; v != super_source; v = static_cast<std::size_t>(parent[v])) {
            const auto u = static_cast<std::size_t>(parent[v]);
            residual[u * node_cap + v] -= amount;
            residual[v * node_cap + u] += amount;
        }
        flow += amount;
    }
    return flow == demand;
}

std::int64_t execute(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 4 || length > max_input) return -1;
    const auto n_value = input[0];
    const auto m_value = input[1];
    const auto source_value = input[2];
    const auto sink_value = input[3];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(max_n) ||
        m_value < 0 || m_value > static_cast<std::int64_t>(max_m)) return -1;
    if (source_value < 0 || source_value >= n_value || sink_value < 0 ||
        sink_value >= n_value || source_value == sink_value) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    const auto source = static_cast<std::size_t>(source_value);
    const auto sink = static_cast<std::size_t>(sink_value);
    if (length != 4 + 4 * m) return -1;

    std::int64_t upper_bound = 0;
    for (std::size_t i = 0; i < m; ++i) {
        const auto offset = 4 + 4 * i;
        const auto u = input[offset];
        const auto v = input[offset + 1];
        const auto lower = input[offset + 2];
        const auto upper = input[offset + 3];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value || lower < 0 ||
            upper < lower || upper > 2) return -1;
        if (static_cast<std::size_t>(u) == source && static_cast<std::size_t>(v) != source)
            upper_bound += upper;
    }

    std::int64_t low = 0;
    std::int64_t high = upper_bound + 1;
    while (low < high) {
        const auto middle = low + (high - low) / 2;
        if (feasible(input, n, m, source, sink, middle)) high = middle;
        else low = middle + 1;
    }
    return low > upper_bound ? -2 : low;
}
} // namespace

extern "C" std::int64_t minimum_bounded_s_t_flow(const std::int64_t* input,
                                                  std::size_t length) {
    return execute(input, length);
}
