/* Binary lifting plus long-chain residual lookup for kth-ancestor queries. */
#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_q = 32;
constexpr std::size_t log_levels = 6;
struct LongChainAncestorState {
    std::array<std::int64_t, max_n> parent{};
    std::array<std::int64_t, max_n> depth{};
    std::array<std::int64_t, max_n> height{};
    std::array<std::int64_t, max_n> heavy{};
    std::array<std::int64_t, max_n> chain_head{};
    std::array<std::int64_t, max_n> chain_position{};
    std::array<std::int64_t, max_n> chain_base{};
    std::array<std::int64_t, max_n> chain_nodes{};
    std::array<std::int64_t, max_n> head_ancestors{};
    std::array<std::array<std::int64_t, max_n>, log_levels> up{};
};

void write_i64(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}  // namespace

extern "C" std::int64_t long_chain_kth_ancestor(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > 130) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > 64 || q_value < 1 || q_value > 32) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    if (length != n + 1 + 2 * q) return -1;
    for (std::size_t vertex = 1; vertex < n; ++vertex)
        if (input[1 + vertex] < 0 || input[1 + vertex] >= static_cast<std::int64_t>(vertex)) return -1;
    const auto query_start = n + 1;
    for (std::size_t query = 0; query < q; ++query) {
        const auto vertex = input[query_start + 2 * query];
        const auto distance = input[query_start + 2 * query + 1];
        if (vertex < 0 || vertex >= n_value || distance < 0 || distance >= 64) return -1;
    }
    const auto required = 8 * q;
    if (output == nullptr || output_capacity < required) return -2;

    LongChainAncestorState state{};
    state.parent[0] = -1;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        state.heavy[vertex] = -1;
        state.chain_head[vertex] = -1;
        state.chain_base[vertex] = -1;
        state.height[vertex] = 1;
        if (vertex > 0) {
            state.parent[vertex] = input[1 + vertex];
            state.depth[vertex] = state.depth[static_cast<std::size_t>(state.parent[vertex])] + 1;
        }
    }
    for (std::size_t reverse = n; reverse > 1; --reverse) {
        const auto vertex = reverse - 1;
        const auto parent = static_cast<std::size_t>(state.parent[vertex]);
        const auto old = state.heavy[parent];
        if (old < 0 || state.height[vertex] > state.height[static_cast<std::size_t>(old)] ||
            (state.height[vertex] == state.height[static_cast<std::size_t>(old)] &&
             static_cast<std::int64_t>(vertex) < old)) state.heavy[parent] = static_cast<std::int64_t>(vertex);
        state.height[parent] = std::max(state.height[parent], state.height[vertex] + 1);
    }

    std::size_t pool = 0;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        if (vertex == 0 || state.heavy[static_cast<std::size_t>(state.parent[vertex])] !=
                           static_cast<std::int64_t>(vertex)) {
            state.chain_base[vertex] = static_cast<std::int64_t>(pool);
            auto current = static_cast<std::int64_t>(vertex);
            std::size_t position = 0;
            while (current >= 0) {
                state.chain_head[static_cast<std::size_t>(current)] = static_cast<std::int64_t>(vertex);
                state.chain_position[static_cast<std::size_t>(current)] = static_cast<std::int64_t>(position);
                state.chain_nodes[pool + position] = current;
                current = state.heavy[static_cast<std::size_t>(current)];
                ++position;
            }
            current = state.parent[vertex];
            for (std::size_t step = 0; step < position; ++step) {
                state.head_ancestors[pool + step] = current;
                current = current >= 0 ? state.parent[static_cast<std::size_t>(current)] : -1;
            }
            pool += position;
        }
    }
    for (std::size_t vertex = 0; vertex < n; ++vertex) state.up[0][vertex] = state.parent[vertex];
    for (std::size_t level = 1; level < log_levels; ++level)
        for (std::size_t vertex = 0; vertex < n; ++vertex) {
            const auto halfway = state.up[level - 1][vertex];
            state.up[level][vertex] = halfway >= 0 ? state.up[level - 1][static_cast<std::size_t>(halfway)] : -1;
        }

    for (std::size_t query = 0; query < q; ++query) {
        const auto vertex = static_cast<std::size_t>(input[query_start + 2 * query]);
        const auto distance = static_cast<std::size_t>(input[query_start + 2 * query + 1]);
        std::int64_t answer = -1;
        if (distance <= static_cast<std::size_t>(state.depth[vertex])) {
            if (distance == 0) answer = static_cast<std::int64_t>(vertex);
            else {
                std::size_t level = 0;
                for (auto value = distance; value > 1; value >>= 1) ++level;
                const auto jumped = static_cast<std::size_t>(state.up[level][vertex]);
                const auto remaining = distance - (std::size_t{1} << level);
                const auto head = static_cast<std::size_t>(state.chain_head[jumped]);
                const auto position = static_cast<std::size_t>(state.chain_position[jumped]);
                const auto base = static_cast<std::size_t>(state.chain_base[head]);
                if (remaining <= position) answer = state.chain_nodes[base + position - remaining];
                else {
                    const auto steps = remaining - position;
                    if (steps <= static_cast<std::size_t>(state.height[head]))
                        answer = state.head_ancestors[base + steps - 1];
                }
            }
        }
        write_i64(output, 8 * query, answer);
    }
    return static_cast<std::int64_t>(required);
}
