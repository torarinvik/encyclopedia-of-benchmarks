#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxVertices = 32;
constexpr int kMaxEdges = 96;
constexpr int kMaxConflicts = 192;
constexpr int kInfiniteLevel = 1000;

struct Interval {
    int low;
    int high;
};

struct ConflictPair {
    Interval left;
    Interval right;
};

struct State {
    int vertex_count = 0;
    int edge_count = 0;
    std::array<int, kMaxEdges> edge_u{};
    std::array<int, kMaxEdges> edge_v{};
    std::array<std::array<int, kMaxVertices>, kMaxVertices> edge_at{};
    std::array<int, kMaxVertices> degree{};
    std::array<std::array<int, kMaxVertices>, kMaxVertices> neighbors{};

    std::array<int, kMaxEdges> tail{};
    std::array<int, kMaxEdges> head{};
    std::array<int, kMaxVertices> height{};
    std::array<int, kMaxVertices> parent_edge{};
    std::array<int, kMaxEdges> low{};
    std::array<int, kMaxEdges> second_low{};
    std::array<int, kMaxEdges> nesting{};

    std::array<int, kMaxVertices> outgoing_count{};
    std::array<std::array<int, kMaxVertices>, kMaxVertices> outgoing{};
    std::array<int, kMaxEdges> reference{};
    std::array<int, kMaxEdges> side{};
    std::array<int, kMaxEdges> low_edge{};
    std::array<int, kMaxEdges> stack_bottom{};
    std::array<ConflictPair, kMaxConflicts> conflict_stack{};
    int conflict_count = 0;

    std::array<int, kMaxVertices> rotation_count{};
    std::array<std::array<int, kMaxVertices>, kMaxVertices> rotation{};
    std::array<int, kMaxVertices> left_reference{};
    std::array<int, kMaxVertices> right_reference{};
    std::array<int, kMaxVertices> roots{};
    int root_count = 0;
};

Interval empty_interval() noexcept { return {-1, -1}; }
bool is_empty(Interval interval) noexcept { return interval.low < 0; }
ConflictPair empty_conflict() noexcept { return {empty_interval(), empty_interval()}; }

void swap_sides(ConflictPair& pair) noexcept {
    const Interval old_left = pair.left;
    pair.left = pair.right;
    pair.right = old_left;
}

void merge_parent_lowpoints(State& state, int edge, int parent) noexcept {
    if (parent < 0) return;
    if (state.low[edge] < state.low[parent]) {
        state.second_low[parent] = state.low[parent] < state.second_low[edge]
            ? state.low[parent] : state.second_low[edge];
        state.low[parent] = state.low[edge];
    } else if (state.low[edge] > state.low[parent]) {
        if (state.low[edge] < state.second_low[parent])
            state.second_low[parent] = state.low[edge];
    } else if (state.second_low[edge] < state.second_low[parent]) {
        state.second_low[parent] = state.second_low[edge];
    }
}

void orient_dfs(State& state, int vertex) {
    const int parent = state.parent_edge[vertex];
    for (int index = 0; index < state.degree[vertex]; ++index) {
        const int next = state.neighbors[vertex][index];
        const int edge = state.edge_at[vertex][next];
        if (state.tail[edge] >= 0) continue;

        state.tail[edge] = vertex;
        state.head[edge] = next;
        state.low[edge] = state.height[vertex];
        state.second_low[edge] = state.height[vertex];
        if (state.height[next] < 0) {
            state.parent_edge[next] = edge;
            state.height[next] = state.height[vertex] + 1;
            orient_dfs(state, next);
            state.nesting[edge] = 2 * state.low[edge]
                + (state.second_low[edge] < state.height[vertex]);
        } else {
            state.low[edge] = state.height[next];
            state.second_low[edge] = state.height[vertex];
            state.nesting[edge] = 2 * state.low[edge]
                + (state.second_low[edge] < state.height[vertex]);
        }
        merge_parent_lowpoints(state, edge, parent);
    }
}

bool interval_conflicts(const State& state, Interval interval, int edge) noexcept {
    return interval.high >= 0 && state.low[interval.high] > state.low[edge];
}

int lowest_conflict_level(const State& state, const ConflictPair& pair) noexcept {
    const int left_level = pair.left.low >= 0
        ? state.low[pair.left.low] : kInfiniteLevel;
    const int right_level = pair.right.low >= 0
        ? state.low[pair.right.low] : kInfiniteLevel;
    return left_level < right_level ? left_level : right_level;
}

bool merge_constraints(State& state, int edge, int parent) noexcept {
    ConflictPair merged = empty_conflict();
    for (;;) {
        if (state.conflict_count == 0) return false;
        ConflictPair current = state.conflict_stack[--state.conflict_count];
        if (!is_empty(current.left)) swap_sides(current);
        if (!is_empty(current.left)) return false;

        if (state.low[current.right.low] > state.low[parent]) {
            if (is_empty(merged.right)) {
                merged.right = current.right;
            } else {
                state.reference[merged.right.low] = current.right.high;
                merged.right.low = current.right.low;
            }
        } else {
            state.reference[current.right.low] = state.low_edge[parent];
        }
        if (state.conflict_count - 1 == state.stack_bottom[edge]) break;
    }

    while (state.conflict_count > 0 &&
           (interval_conflicts(state, state.conflict_stack[state.conflict_count - 1].left, edge) ||
            interval_conflicts(state, state.conflict_stack[state.conflict_count - 1].right, edge))) {
        ConflictPair current = state.conflict_stack[--state.conflict_count];
        if (interval_conflicts(state, current.right, edge)) swap_sides(current);
        if (interval_conflicts(state, current.right, edge)) return false;
        if (merged.right.low >= 0) state.reference[merged.right.low] = current.right.high;
        if (current.right.low >= 0) merged.right.low = current.right.low;
        if (is_empty(merged.left)) {
            merged.left = current.left;
        } else {
            state.reference[merged.left.low] = current.left.high;
            merged.left.low = current.left.low;
        }
    }
    if (!is_empty(merged.left) || !is_empty(merged.right))
        state.conflict_stack[state.conflict_count++] = merged;
    return true;
}

void remove_parent_returns(State& state, int edge) noexcept {
    const int vertex = state.tail[edge];
    while (state.conflict_count > 0 &&
           lowest_conflict_level(state, state.conflict_stack[state.conflict_count - 1]) ==
               state.height[vertex]) {
        const ConflictPair pair = state.conflict_stack[--state.conflict_count];
        if (pair.left.low >= 0) state.side[pair.left.low] = -1;
    }

    if (state.conflict_count > 0) {
        ConflictPair pair = state.conflict_stack[--state.conflict_count];
        while (pair.left.high >= 0 && state.head[pair.left.high] == vertex)
            pair.left.high = state.reference[pair.left.high];
        if (pair.left.high < 0 && pair.left.low >= 0) {
            state.reference[pair.left.low] = pair.right.low;
            state.side[pair.left.low] = -1;
            pair.left.low = -1;
        }
        while (pair.right.high >= 0 && state.head[pair.right.high] == vertex)
            pair.right.high = state.reference[pair.right.high];
        if (pair.right.high < 0 && pair.right.low >= 0) {
            state.reference[pair.right.low] = pair.left.low;
            state.side[pair.right.low] = -1;
            pair.right.low = -1;
        }
        state.conflict_stack[state.conflict_count++] = pair;
    }

    if (state.low[edge] < state.height[vertex] && state.conflict_count > 0) {
        const ConflictPair& pair = state.conflict_stack[state.conflict_count - 1];
        const int left_high = pair.left.high;
        const int right_high = pair.right.high;
        state.reference[edge] = left_high >= 0 &&
                (right_high < 0 || state.low[left_high] > state.low[right_high])
            ? left_high : right_high;
    }
}

bool test_dfs(State& state, int vertex) {
    const int parent = state.parent_edge[vertex];
    for (int index = 0; index < state.outgoing_count[vertex]; ++index) {
        const int edge = state.outgoing[vertex][index];
        const int next = state.head[edge];
        state.stack_bottom[edge] = state.conflict_count - 1;
        if (state.parent_edge[next] == edge) {
            if (!test_dfs(state, next)) return false;
        } else {
            state.low_edge[edge] = edge;
            ConflictPair singleton = empty_conflict();
            singleton.right = {edge, edge};
            state.conflict_stack[state.conflict_count++] = singleton;
            if (state.low[edge] < state.height[vertex]) {
                if (index == 0) {
                    if (parent >= 0) state.low_edge[parent] = state.low_edge[edge];
                } else if (parent < 0 || !merge_constraints(state, edge, parent)) {
                    return false;
                }
            }
        }
    }
    if (parent >= 0) remove_parent_returns(state, parent);
    return true;
}

int resolve_side(State& state, int edge) {
    if (state.reference[edge] >= 0) {
        const int referenced = state.reference[edge];
        state.side[edge] *= resolve_side(state, referenced);
        state.reference[edge] = -1;
    }
    return state.side[edge];
}

bool edge_precedes(const State& state, int first, int second,
                   const std::array<int, kMaxEdges>& depth) noexcept {
    return depth[first] < depth[second] ||
        (depth[first] == depth[second] && state.head[first] < state.head[second]);
}

void insert_rotation(State& state, int vertex, int neighbor, int reference, bool after) noexcept {
    const int count = state.rotation_count[vertex];
    int position = 0;
    if (count > 0 && reference >= 0) {
        while (position < count && state.rotation[vertex][position] != reference) ++position;
        if (position == count) {
            position = count;
        } else if (after) {
            position = (position + 1) % count;
        }
    }
    for (int index = count; index > position; --index)
        state.rotation[vertex][index] = state.rotation[vertex][index - 1];
    state.rotation[vertex][position] = neighbor;
    state.rotation_count[vertex] = count + 1;
}

void embed_dfs(State& state, int vertex) {
    for (int index = 0; index < state.outgoing_count[vertex]; ++index) {
        const int edge = state.outgoing[vertex][index];
        const int next = state.head[edge];
        if (state.parent_edge[next] == edge) {
            insert_rotation(state, next, vertex, -1, false);
            state.left_reference[vertex] = next;
            state.right_reference[vertex] = next;
            embed_dfs(state, next);
        } else if (state.side[edge] == 1) {
            insert_rotation(state, next, vertex, state.right_reference[next], true);
        } else {
            insert_rotation(state, next, vertex, state.left_reference[next], false);
            state.left_reference[next] = vertex;
        }
    }
}

}  // namespace

extern "C" std::int64_t planar_embedding_lr(const std::int64_t* input, std::size_t length,
                                               std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 195) return -1;
    const std::int64_t vertices64 = input[0];
    const std::int64_t edges64 = input[1];
    if (vertices64 < 1 || vertices64 > kMaxVertices || edges64 < 0 || edges64 > kMaxEdges ||
        length != 2 + 2 * static_cast<std::size_t>(edges64)) return -1;

    State state{};
    state.vertex_count = static_cast<int>(vertices64);
    state.edge_count = static_cast<int>(edges64);
    for (int u = 0; u < state.vertex_count; ++u)
        state.edge_at[u].fill(-1);
    for (int vertex = 0; vertex < state.vertex_count; ++vertex) {
        state.height[vertex] = -1;
        state.parent_edge[vertex] = -1;
        state.left_reference[vertex] = -1;
        state.right_reference[vertex] = -1;
    }
    for (int edge = 0; edge < state.edge_count; ++edge) {
        state.tail[edge] = -1;
        state.head[edge] = -1;
        state.reference[edge] = -1;
        state.low_edge[edge] = -1;
        state.stack_bottom[edge] = -1;
        state.side[edge] = 1;
        const std::int64_t u64 = input[2 + 2 * static_cast<std::size_t>(edge)];
        const std::int64_t v64 = input[3 + 2 * static_cast<std::size_t>(edge)];
        if (u64 < 0 || u64 >= v64 || v64 >= vertices64) return -1;
        const int u = static_cast<int>(u64);
        const int v = static_cast<int>(v64);
        if (state.edge_at[u][v] >= 0) return -1;
        state.edge_u[edge] = u;
        state.edge_v[edge] = v;
        state.edge_at[u][v] = edge;
        state.edge_at[v][u] = edge;
    }

    for (int vertex = 0; vertex < state.vertex_count; ++vertex) {
        for (int next = 0; next < state.vertex_count; ++next) {
            if (state.edge_at[vertex][next] >= 0)
                state.neighbors[vertex][state.degree[vertex]++] = next;
        }
    }
    for (int root = 0; root < state.vertex_count; ++root) {
        if (state.height[root] >= 0) continue;
        state.height[root] = 0;
        state.roots[state.root_count++] = root;
        orient_dfs(state, root);
    }

    for (int edge = 0; edge < state.edge_count; ++edge) {
        const int tail = state.tail[edge];
        state.outgoing[tail][state.outgoing_count[tail]++] = edge;
    }
    for (int vertex = 0; vertex < state.vertex_count; ++vertex) {
        for (int index = 1; index < state.outgoing_count[vertex]; ++index) {
            const int edge = state.outgoing[vertex][index];
            int position = index;
            while (position > 0 && edge_precedes(
                       state, edge, state.outgoing[vertex][position - 1], state.nesting)) {
                state.outgoing[vertex][position] = state.outgoing[vertex][position - 1];
                --position;
            }
            state.outgoing[vertex][position] = edge;
        }
    }

    bool planar = true;
    for (int index = 0; index < state.root_count; ++index) {
        if (!test_dfs(state, state.roots[index])) {
            planar = false;
            break;
        }
    }
    if (output == nullptr) return -2;
    if (!planar) {
        if (capacity < 1) return -2;
        output[0] = 0;
        return 1;
    }

    std::array<int, kMaxEdges> signed_depth{};
    for (int edge = 0; edge < state.edge_count; ++edge)
        signed_depth[edge] = state.nesting[edge] * resolve_side(state, edge);
    for (int vertex = 0; vertex < state.vertex_count; ++vertex) {
        for (int index = 1; index < state.outgoing_count[vertex]; ++index) {
            const int edge = state.outgoing[vertex][index];
            int position = index;
            while (position > 0 && edge_precedes(
                       state, edge, state.outgoing[vertex][position - 1], signed_depth)) {
                state.outgoing[vertex][position] = state.outgoing[vertex][position - 1];
                --position;
            }
            state.outgoing[vertex][position] = edge;
        }
    }
    for (int vertex = 0; vertex < state.vertex_count; ++vertex) {
        for (int index = 0; index < state.outgoing_count[vertex]; ++index) {
            state.rotation[vertex][state.rotation_count[vertex]++] =
                state.head[state.outgoing[vertex][index]];
        }
    }
    for (int index = 0; index < state.root_count; ++index)
        embed_dfs(state, state.roots[index]);

    const std::size_t needed = 1 + 2 * static_cast<std::size_t>(state.edge_count);
    if (capacity < needed) return -2;
    output[0] = 1;
    std::size_t offset = 1;
    for (int vertex = 0; vertex < state.vertex_count; ++vertex) {
        for (int index = 0; index < state.rotation_count[vertex]; ++index)
            output[offset++] = static_cast<std::uint8_t>(state.rotation[vertex][index]);
    }
    return static_cast<std::int64_t>(needed);
}
