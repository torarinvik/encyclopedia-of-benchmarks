/* DSU-on-tree distinct-color counts for all rooted subtrees. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_colors = 256;

struct SackState {
    std::size_t n{};
    std::array<int, max_n> parent{};
    std::array<int, max_n> first_child{};
    std::array<int, max_n> next_sibling{};
    std::array<std::size_t, max_n> order{};
    std::array<std::size_t, max_n> tin{};
    std::array<std::size_t, max_n> subtree_size{};
    std::array<int, max_n> heavy{};
    std::array<std::size_t, max_colors> frequency{};
    std::array<std::size_t, max_n> answer{};
    std::size_t distinct{};
    std::array<int, max_n> frame_vertex{};
    std::array<int, max_n> frame_keep{};
    std::array<int, max_n> frame_stage{};
    std::array<int, max_n> frame_child{};
};

void add_interval(SackState& state, std::size_t begin, std::size_t count,
                  const std::array<int, max_n>& colors, int delta) {
    for (std::size_t i = begin; i < begin + count; ++i) {
        const auto color = static_cast<std::size_t>(colors[state.order[i]]);
        if (delta > 0) {
            if (state.frequency[color] == 0) ++state.distinct;
            ++state.frequency[color];
        } else {
            --state.frequency[color];
            if (state.frequency[color] == 0) --state.distinct;
        }
    }
}

void solve_sack(SackState& state, const std::array<int, max_n>& colors) {
    std::array<int, max_n> stack_next{};
    int depth = 0;
    std::size_t timer = 1;
    state.order[0] = 0;
    state.tin[0] = 0;
    stack_next[0] = state.first_child[0];
    while (depth >= 0) {
        const int child = stack_next[static_cast<std::size_t>(depth)];
        if (child >= 0) {
            stack_next[static_cast<std::size_t>(depth)] = state.next_sibling[static_cast<std::size_t>(child)];
            ++depth;
            stack_next[static_cast<std::size_t>(depth)] = state.first_child[static_cast<std::size_t>(child)];
            state.tin[static_cast<std::size_t>(child)] = timer;
            state.order[timer++] = static_cast<std::size_t>(child);
        } else {
            --depth;
        }
    }

    for (std::size_t vertex = 0; vertex < state.n; ++vertex) {
        state.subtree_size[vertex] = 1;
        state.heavy[vertex] = -1;
    }
    for (std::size_t i = state.n; i > 1; --i) {
        const int vertex = static_cast<int>(state.order[i - 1]);
        const int parent = state.parent[static_cast<std::size_t>(vertex)];
        state.subtree_size[static_cast<std::size_t>(parent)] += state.subtree_size[static_cast<std::size_t>(vertex)];
        const int previous = state.heavy[static_cast<std::size_t>(parent)];
        if (previous < 0 || state.subtree_size[static_cast<std::size_t>(vertex)] >
                            state.subtree_size[static_cast<std::size_t>(previous)])
            state.heavy[static_cast<std::size_t>(parent)] = vertex;
    }

    int top = 0;
    state.frame_vertex[0] = 0;
    state.frame_keep[0] = 0;
    state.frame_stage[0] = 0;
    state.frame_child[0] = state.first_child[0];
    while (top >= 0) {
        const auto frame = static_cast<std::size_t>(top);
        const int vertex = state.frame_vertex[frame];
        if (state.frame_stage[frame] == 0) {
            int child = state.frame_child[frame];
            while (child >= 0 && child == state.heavy[static_cast<std::size_t>(vertex)])
                child = state.next_sibling[static_cast<std::size_t>(child)];
            if (child >= 0) {
                state.frame_child[frame] = state.next_sibling[static_cast<std::size_t>(child)];
                ++top;
                const auto next_frame = static_cast<std::size_t>(top);
                state.frame_vertex[next_frame] = child;
                state.frame_keep[next_frame] = 0;
                state.frame_stage[next_frame] = 0;
                state.frame_child[next_frame] = state.first_child[static_cast<std::size_t>(child)];
            } else {
                state.frame_stage[frame] = 1;
            }
        } else if (state.frame_stage[frame] == 1) {
            state.frame_stage[frame] = 2;
            const int child = state.heavy[static_cast<std::size_t>(vertex)];
            if (child >= 0) {
                ++top;
                const auto next_frame = static_cast<std::size_t>(top);
                state.frame_vertex[next_frame] = child;
                state.frame_keep[next_frame] = 1;
                state.frame_stage[next_frame] = 0;
                state.frame_child[next_frame] = state.first_child[static_cast<std::size_t>(child)];
            }
        } else {
            for (int child = state.first_child[static_cast<std::size_t>(vertex)]; child >= 0;
                 child = state.next_sibling[static_cast<std::size_t>(child)]) {
                if (child != state.heavy[static_cast<std::size_t>(vertex)])
                    add_interval(state, state.tin[static_cast<std::size_t>(child)],
                                 state.subtree_size[static_cast<std::size_t>(child)], colors, 1);
            }
            const auto color = static_cast<std::size_t>(colors[static_cast<std::size_t>(vertex)]);
            if (state.frequency[color] == 0) ++state.distinct;
            ++state.frequency[color];
            state.answer[static_cast<std::size_t>(vertex)] = state.distinct;
            if (state.frame_keep[frame] == 0)
                add_interval(state, state.tin[static_cast<std::size_t>(vertex)],
                             state.subtree_size[static_cast<std::size_t>(vertex)], colors, -1);
            --top;
        }
    }
}

void write_i64(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}  // namespace

extern "C" std::int64_t tree_subtree_distinct_sack(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > 130) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > 64 || length != 2 * static_cast<std::size_t>(n_value)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    std::array<int, max_n> colors{};
    for (std::size_t vertex = 1; vertex < n; ++vertex)
        if (input[vertex] < 0 || input[vertex] >= static_cast<std::int64_t>(vertex)) return -1;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        const auto color = input[n + vertex];
        if (color < 0 || color >= static_cast<std::int64_t>(max_colors)) return -1;
        colors[vertex] = static_cast<int>(color);
    }
    const auto required = 8 * n;
    if (output == nullptr || output_capacity < required) return -2;

    SackState state{};
    state.n = n;
    state.first_child.fill(-1);
    for (std::size_t vertex = 1; vertex < n; ++vertex) {
        const int parent = static_cast<int>(input[vertex]);
        state.parent[vertex] = parent;
        state.next_sibling[vertex] = state.first_child[static_cast<std::size_t>(parent)];
        state.first_child[static_cast<std::size_t>(parent)] = static_cast<int>(vertex);
    }
    solve_sack(state, colors);
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        write_i64(output, 8 * vertex, static_cast<std::int64_t>(state.answer[vertex]));
    return static_cast<std::int64_t>(required);
}
