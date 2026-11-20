#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 8;
constexpr std::size_t kMaxEdges = 16;
constexpr std::size_t kMaxInput = 51;
constexpr std::size_t kOutputBytes = 16;

struct Edge { std::size_t from; std::size_t to; std::int64_t weight; };

bool all_reachable(std::size_t n,
    const std::array<std::array<bool, kMaxVertices>, kMaxVertices>& adjacent,
    bool reverse) noexcept {
    std::array<bool, kMaxVertices> seen{};
    std::array<std::size_t, kMaxVertices> queue{};
    std::size_t head = 0;
    std::size_t tail = 0;
    seen[0] = true;
    queue[tail++] = 0;
    while (head < tail) {
        const auto u = queue[head++];
        for (std::size_t v = 0; v < n; ++v) {
            const bool has_edge = reverse ? adjacent[v][u] : adjacent[u][v];
            if (has_edge && !seen[v]) {
                seen[v] = true;
                queue[tail++] = v;
            }
        }
    }
    for (std::size_t v = 0; v < n; ++v) if (!seen[v]) return false;
    return true;
}

std::int64_t gcd_positive(std::int64_t a, std::int64_t b) noexcept {
    while (b != 0) {
        const auto remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

int compare_ratio(std::int64_t a_num, std::int64_t a_den,
                  std::int64_t b_num, std::int64_t b_den) noexcept {
    const auto left = a_num * b_den;
    const auto right = b_num * a_den;
    return left < right ? -1 : left > right ? 1 : 0;
}

int compare_appraisal(std::size_t a_id, std::size_t b_id,
    const std::array<Edge, kMaxEdges>& edges,
    const std::array<std::int64_t, kMaxVertices>& value_num,
    const std::array<std::int64_t, kMaxVertices>& value_den,
    const std::array<std::int64_t, kMaxVertices>& bias_num) noexcept {
    const auto& a = edges[a_id];
    const auto& b = edges[b_id];
    int comparison = compare_ratio(value_num[a.to], value_den[a.to],
                                   value_num[b.to], value_den[b.to]);
    if (comparison != 0) return comparison;
    const auto a_bias = a.weight * value_den[a.to] - value_num[a.to] + bias_num[a.to];
    const auto b_bias = b.weight * value_den[b.to] - value_num[b.to] + bias_num[b.to];
    return compare_ratio(a_bias, value_den[a.to], b_bias, value_den[b.to]);
}

void evaluate_policy(std::size_t n, const std::array<Edge, kMaxEdges>& edges,
    const std::array<std::size_t, kMaxVertices>& policy,
    std::array<std::int64_t, kMaxVertices>& value_num,
    std::array<std::int64_t, kMaxVertices>& value_den,
    std::array<std::int64_t, kMaxVertices>& bias_num) noexcept {
    std::array<bool, kMaxVertices> assigned{};
    for (std::size_t start = 0; start < n; ++start) {
        if (assigned[start]) continue;
        std::array<int, kMaxVertices> local_position{};
        local_position.fill(-1);
        std::array<std::size_t, kMaxVertices> path{};
        std::size_t path_length = 0;
        std::size_t vertex = start;
        while (!assigned[vertex] && local_position[vertex] < 0) {
            local_position[vertex] = static_cast<int>(path_length);
            path[path_length++] = vertex;
            vertex = edges[policy[vertex]].to;
        }

        std::size_t prefix_length = path_length;
        if (!assigned[vertex]) {
            const auto cycle_start = static_cast<std::size_t>(local_position[vertex]);
            const auto cycle_length = path_length - cycle_start;
            std::int64_t cycle_weight = 0;
            std::size_t head_position = cycle_start;
            for (std::size_t i = cycle_start; i < path_length; ++i) {
                const auto u = path[i];
                cycle_weight += edges[policy[u]].weight;
                if (path[i] < path[head_position]) head_position = i;
            }
            const auto absolute_weight = cycle_weight < 0 ? -cycle_weight : cycle_weight;
            const auto divisor = gcd_positive(absolute_weight, static_cast<std::int64_t>(cycle_length));
            const auto mean_num = cycle_weight / divisor;
            const auto mean_den = static_cast<std::int64_t>(cycle_length) / divisor;
            const auto head = path[head_position];
            for (std::size_t i = cycle_start; i < path_length; ++i) {
                const auto u = path[i];
                value_num[u] = mean_num;
                value_den[u] = mean_den;
                assigned[u] = true;
            }

            bias_num[head] = 0;
            auto current_position = head_position;
            for (;;) {
                const auto previous_position = current_position == cycle_start
                    ? path_length - 1 : current_position - 1;
                const auto previous = path[previous_position];
                if (previous == head) break;
                bias_num[previous] = edges[policy[previous]].weight * mean_den
                    - mean_num + bias_num[path[current_position]];
                current_position = previous_position;
            }
            prefix_length = cycle_start;
        }

        for (std::size_t i = prefix_length; i > 0; --i) {
            const auto u = path[i - 1];
            const auto successor = edges[policy[u]].to;
            value_num[u] = value_num[successor];
            value_den[u] = value_den[successor];
            bias_num[u] = edges[policy[u]].weight * value_den[successor]
                - value_num[successor] + bias_num[successor];
            assigned[u] = true;
        }
    }
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
} // namespace

extern "C" std::int64_t minimum_mean_cycle_howard(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxVertices)
        || input[1] < 1 || input[1] > static_cast<std::int64_t>(kMaxEdges)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto edge_count = static_cast<std::size_t>(input[1]);
    if (edge_count > n * n || length != 2 + 3 * edge_count) return -1;

    std::array<Edge, kMaxEdges> edges{};
    std::array<std::array<bool, kMaxVertices>, kMaxVertices> adjacent{};
    std::array<std::array<std::uint8_t, kMaxEdges>, kMaxVertices> outgoing{};
    std::array<std::size_t, kMaxVertices> degree{};
    std::array<std::size_t, kMaxVertices> policy{};
    for (std::size_t i = 0; i < edge_count; ++i) {
        const auto from_value = input[2 + 3 * i];
        const auto to_value = input[3 + 3 * i];
        const auto weight = input[4 + 3 * i];
        if (from_value < 0 || from_value >= static_cast<std::int64_t>(n)
            || to_value < 0 || to_value >= static_cast<std::int64_t>(n)
            || weight < -1000 || weight > 1000) return -1;
        const auto from = static_cast<std::size_t>(from_value);
        const auto to = static_cast<std::size_t>(to_value);
        if (adjacent[from][to]) return -1;
        adjacent[from][to] = true;
        edges[i] = {from, to, weight};
        outgoing[from][degree[from]++] = static_cast<std::uint8_t>(i);
        if (degree[from] == 1) policy[from] = i;
    }
    if (!all_reachable(n, adjacent, false) || !all_reachable(n, adjacent, true)) return -1;
    if (output == nullptr || capacity < kOutputBytes) return -2;

    std::size_t policy_limit = 1;
    for (std::size_t u = 0; u < n; ++u) policy_limit *= degree[u];
    std::array<std::int64_t, kMaxVertices> value_num{};
    std::array<std::int64_t, kMaxVertices> value_den{};
    std::array<std::int64_t, kMaxVertices> bias_num{};
    value_den.fill(1);
    bool converged = false;
    for (std::size_t iteration = 0; iteration < policy_limit; ++iteration) {
        evaluate_policy(n, edges, policy, value_num, value_den, bias_num);
        auto improved = policy;
        bool changed = false;
        for (std::size_t u = 0; u < n; ++u) {
            auto best = policy[u];
            for (std::size_t j = 0; j < degree[u]; ++j) {
                const auto candidate = static_cast<std::size_t>(outgoing[u][j]);
                if (compare_appraisal(candidate, best, edges, value_num, value_den, bias_num) < 0)
                    best = candidate;
            }
            improved[u] = best;
            if (best != policy[u]) changed = true;
        }
        if (!changed) {
            converged = true;
            break;
        }
        policy = improved;
    }
    if (!converged) return -1;

    std::size_t best_vertex = 0;
    for (std::size_t v = 1; v < n; ++v) {
        if (compare_ratio(value_num[v], value_den[v],
                          value_num[best_vertex], value_den[best_vertex]) < 0) best_vertex = v;
    }
    auto answer_num = value_num[best_vertex];
    auto answer_den = value_den[best_vertex];
    const auto divisor = gcd_positive(answer_num < 0 ? -answer_num : answer_num, answer_den);
    answer_num /= divisor;
    answer_den /= divisor;
    std::array<std::uint8_t, kOutputBytes> staged{};
    store_i64_le(staged.data(), 0, answer_num);
    store_i64_le(staged.data(), 8, answer_den);
    for (std::size_t i = 0; i < kOutputBytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(kOutputBytes);
}
