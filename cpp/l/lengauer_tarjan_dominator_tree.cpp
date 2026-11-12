// Simple Lengauer-Tarjan immediate dominators with iterative path compression.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_v = 63;
constexpr int max_e = 2047;
constexpr std::size_t max_input = 4097;

int evaluate(int vertex, std::array<int, max_v + 1>& ancestor,
             std::array<int, max_v + 1>& label,
             const std::array<int, max_v + 1>& semi,
             std::array<int, max_v + 1>& path) {
    if (ancestor[vertex] == 0) return vertex;
    int used = 0, current = vertex;
    while (ancestor[ancestor[current]] != 0) {
        path[used++] = current;
        current = ancestor[current];
    }
    while (used > 0) {
        current = path[--used];
        const int parent = ancestor[current];
        if (semi[label[parent]] < semi[label[current]]) label[current] = label[parent];
        ancestor[current] = ancestor[parent];
    }
    return label[vertex];
}
}

extern "C" std::int64_t lengauer_tarjan_dominator_tree(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    const auto nv = input[0], root_value = input[1], me = input[2];
    if (nv < 1 || nv > max_v || root_value < 0 || root_value >= nv || me < 0 || me > max_e) return -1;
    const int n = static_cast<int>(nv), root = static_cast<int>(root_value), m = static_cast<int>(me);
    if (length != 3 + 2 * static_cast<std::size_t>(m)) return -1;

    std::array<std::uint64_t, max_v> outmask{};
    std::array<int, max_v> out_head{};
    std::array<int, max_e> edge_source{}, edge_target{}, out_next{}, pred_next{};
    std::array<int, max_v + 1> pred_head{}, vertex_at{}, parent{}, semi{};
    std::array<int, max_v + 1> ancestor{}, label{}, immediate{}, bucket_head{}, bucket_next{};
    std::array<int, max_v> dfs_number{}, node_stack{}, edge_stack{};
    std::array<int, max_v + 1> eval_path{};
    std::array<std::uint8_t, max_v> staged{};
    for (int v = 0; v < n; ++v) out_head[v] = -1;
    pred_head.fill(-1);
    bucket_head.fill(-1);

    int edge_count = 0;
    for (int i = 0; i < m; ++i) {
        const auto sv = input[3 + 2 * i], tv = input[4 + 2 * i];
        if (sv < 0 || sv >= nv || tv < 0 || tv >= nv) return -1;
        const int source = static_cast<int>(sv), target = static_cast<int>(tv);
        const std::uint64_t bit = std::uint64_t{1} << target;
        if ((outmask[source] & bit) == 0) {
            outmask[source] |= bit;
            edge_source[edge_count] = source;
            edge_target[edge_count] = target;
            out_next[edge_count] = out_head[source];
            out_head[source] = edge_count++;
        }
    }

    int dfs_count = 1, top = 1;
    dfs_number[root] = 1;
    vertex_at[1] = root;
    node_stack[0] = root;
    edge_stack[0] = out_head[root];
    while (top > 0) {
        const int frame = top - 1, current = node_stack[frame], edge = edge_stack[frame];
        if (edge == -1) { --top; continue; }
        edge_stack[frame] = out_next[edge];
        const int target = edge_target[edge];
        if (dfs_number[target] == 0) {
            const int number = ++dfs_count;
            dfs_number[target] = number;
            vertex_at[number] = target;
            parent[number] = dfs_number[current];
            node_stack[top] = target;
            edge_stack[top] = out_head[target];
            ++top;
        }
    }

    for (int edge = 0; edge < edge_count; ++edge) {
        const int source_number = dfs_number[edge_source[edge]];
        const int target_number = dfs_number[edge_target[edge]];
        if (source_number != 0 && target_number != 0) {
            pred_next[edge] = pred_head[target_number];
            pred_head[target_number] = edge;
        }
    }
    for (int v = 1; v <= dfs_count; ++v) semi[v] = label[v] = v;

    for (int w = dfs_count; w >= 2; --w) {
        for (int edge = pred_head[w]; edge != -1; edge = pred_next[edge]) {
            const int predecessor = dfs_number[edge_source[edge]];
            const int representative = evaluate(predecessor, ancestor, label, semi, eval_path);
            if (semi[representative] < semi[w]) semi[w] = semi[representative];
        }
        bucket_next[w] = bucket_head[semi[w]];
        bucket_head[semi[w]] = w;
        ancestor[w] = parent[w];

        const int owner = parent[w];
        int member = bucket_head[owner];
        bucket_head[owner] = -1;
        while (member != -1) {
            const int next = bucket_next[member];
            const int representative = evaluate(member, ancestor, label, semi, eval_path);
            immediate[member] = semi[representative] < semi[member] ? representative : owner;
            member = next;
        }
    }
    for (int w = 2; w <= dfs_count; ++w)
        if (immediate[w] != semi[w]) immediate[w] = immediate[immediate[w]];
    immediate[1] = 1;

    for (int v = 0; v < n; ++v) {
        const int number = dfs_number[v];
        staged[v] = number == 0 ? UINT8_MAX : static_cast<std::uint8_t>(vertex_at[immediate[number]]);
    }
    if (output == nullptr || capacity < static_cast<std::size_t>(n)) return -2;
    for (int v = 0; v < n; ++v) output[v] = staged[v];
    return n;
}
