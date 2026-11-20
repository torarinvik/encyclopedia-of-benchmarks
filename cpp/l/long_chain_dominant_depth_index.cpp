/* Long-chain DP for the smallest dominant subtree depth. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
struct LongChainState {
    std::array<std::int64_t, max_n> parent{};
    std::array<std::int64_t, max_n> first_child{};
    std::array<std::int64_t, max_n> next_sibling{};
    std::array<std::int64_t, max_n> height{};
    std::array<std::int64_t, max_n> heavy{};
    std::array<std::int64_t, max_n> base{};
    std::array<std::int64_t, max_n> count{};
    std::array<std::int64_t, max_n> dominant_depth{};
};

void write_i64(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}  // namespace

extern "C" std::int64_t long_chain_dominant_depth_index(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t output_capacity) {
    if (input == nullptr || length == 0 || length > 65) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > 64 || length != static_cast<std::size_t>(n_value)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    for (std::size_t vertex = 1; vertex < n; ++vertex)
        if (input[vertex] < 0 || input[vertex] >= static_cast<std::int64_t>(vertex)) return -1;
    const auto required = 8 * n;
    if (output == nullptr || output_capacity < required) return -2;

    LongChainState state{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        state.first_child[vertex] = -1;
        state.heavy[vertex] = -1;
        state.height[vertex] = 1;
    }
    state.parent[0] = -1;
    for (std::size_t vertex = 1; vertex < n; ++vertex) {
        const auto parent = input[vertex];
        state.parent[vertex] = parent;
        state.next_sibling[vertex] = state.first_child[static_cast<std::size_t>(parent)];
        state.first_child[static_cast<std::size_t>(parent)] = static_cast<std::int64_t>(vertex);
    }

    for (std::size_t reverse = n; reverse > 0; --reverse) {
        const auto vertex = reverse - 1;
        auto child = state.first_child[vertex];
        std::int64_t maximum_height = 0;
        while (child >= 0) {
            const auto child_index = static_cast<std::size_t>(child);
            const auto child_height = state.height[child_index];
            if (child_height > maximum_height ||
                (child_height == maximum_height && child < state.heavy[vertex])) {
                maximum_height = child_height;
                state.heavy[vertex] = child;
            }
            child = state.next_sibling[child_index];
        }
        state.height[vertex] = maximum_height + 1;
    }

    std::int64_t pool_size = 0;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        if (vertex == 0 || state.heavy[static_cast<std::size_t>(state.parent[vertex])] !=
                           static_cast<std::int64_t>(vertex)) {
            auto current = static_cast<std::int64_t>(vertex);
            while (current >= 0) {
                state.base[static_cast<std::size_t>(current)] = pool_size++;
                current = state.heavy[static_cast<std::size_t>(current)];
            }
        }
    }

    for (std::size_t reverse = n; reverse > 0; --reverse) {
        const auto vertex = reverse - 1;
        const auto base = static_cast<std::size_t>(state.base[vertex]);
        state.count[base] = 1;
        std::int64_t best_depth = 0;
        std::int64_t best_count = 1;
        const auto heavy = state.heavy[vertex];
        if (heavy >= 0) {
            const auto heavy_index = static_cast<std::size_t>(heavy);
            best_depth = state.dominant_depth[heavy_index] + 1;
            best_count = state.count[base + static_cast<std::size_t>(best_depth)];
        }
        for (auto child = state.first_child[vertex]; child >= 0;
             child = state.next_sibling[static_cast<std::size_t>(child)]) {
            if (child == heavy) continue;
            const auto child_index = static_cast<std::size_t>(child);
            const auto child_base = static_cast<std::size_t>(state.base[child_index]);
            for (std::int64_t child_depth = 0; child_depth < state.height[child_index]; ++child_depth) {
                const auto depth = child_depth + 1;
                const auto slot = base + static_cast<std::size_t>(depth);
                const auto count = state.count[slot] +
                                   state.count[child_base + static_cast<std::size_t>(child_depth)];
                state.count[slot] = count;
                if (count > best_count || (count == best_count && depth < best_depth)) {
                    best_count = count;
                    best_depth = depth;
                }
            }
        }
        state.dominant_depth[vertex] = best_depth;
    }
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        write_i64(output, 8 * vertex, state.dominant_depth[vertex]);
    return static_cast<std::int64_t>(required);
}
