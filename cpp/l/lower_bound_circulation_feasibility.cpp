#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 6;
constexpr std::size_t max_m = 8;
constexpr std::size_t max_input = 35;
constexpr std::size_t node_cap = 8;
constexpr std::size_t matrix_cap = node_cap * node_cap;

std::int64_t execute(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n_value = input[0];
    const auto m_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        m_value < 0 || m_value > static_cast<std::int64_t>(max_m)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    if (length != 2 + 4 * m) return -1;

    std::array<std::int64_t, matrix_cap> residual{};
    std::array<std::int64_t, max_n> balance{};
    for (std::size_t i = 0; i < m; ++i) {
        const auto offset = 2 + 4 * i;
        const auto u_value = input[offset];
        const auto v_value = input[offset + 1];
        const auto lower = input[offset + 2];
        const auto upper = input[offset + 3];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
            lower < 0 || upper < lower || upper > 2) return -1;
        const auto u = static_cast<std::size_t>(u_value);
        const auto v = static_cast<std::size_t>(v_value);
        residual[u * node_cap + v] += upper - lower;
        balance[u] -= lower;
        balance[v] += lower;
    }

    const auto source = n;
    const auto sink = n + 1;
    const auto node_count = n + 2;
    std::int64_t demand = 0;
    for (std::size_t v = 0; v < n; ++v) {
        if (balance[v] > 0) {
            residual[source * node_cap + v] += balance[v];
            demand += balance[v];
        } else if (balance[v] < 0) {
            residual[v * node_cap + sink] += -balance[v];
        }
    }

    std::int64_t flow = 0;
    while (flow < demand) {
        std::array<int, node_cap> parent;
        parent.fill(-1);
        std::array<std::size_t, node_cap> queue{};
        std::size_t head = 0;
        std::size_t tail = 0;
        parent[source] = static_cast<int>(source);
        queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            const auto u = queue[head++];
            for (std::size_t v = 0; v < node_count; ++v) {
                if (residual[u * node_cap + v] > 0 && parent[v] < 0) {
                    parent[v] = static_cast<int>(u);
                    queue[tail++] = v;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) break;
        auto amount = demand - flow;
        for (auto v = sink; v != source; v = static_cast<std::size_t>(parent[v])) {
            const auto u = static_cast<std::size_t>(parent[v]);
            amount = std::min(amount, residual[u * node_cap + v]);
        }
        for (auto v = sink; v != source; v = static_cast<std::size_t>(parent[v])) {
            const auto u = static_cast<std::size_t>(parent[v]);
            residual[u * node_cap + v] -= amount;
            residual[v * node_cap + u] += amount;
        }
        flow += amount;
    }
    return flow == demand ? 1 : 0;
}
} // namespace

extern "C" std::int64_t lower_bound_circulation_feasibility(const std::int64_t* input,
                                                              std::size_t length) {
    return execute(input, length);
}
