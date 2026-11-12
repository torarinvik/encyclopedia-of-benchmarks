/* Simple Lengauer-Tarjan immediate dominators with iterative path compression. */
#include <stddef.h>
#include <stdint.h>

#define LT_MAX_V 63
#define LT_MAX_E 2047
#define LT_MAX_INPUT 4097

static int lt_eval(int vertex, int *ancestor, int *label, const int *semi, int *path)
{
    if (ancestor[vertex] == 0) return vertex;
    int used = 0, current = vertex;
    while (ancestor[ancestor[current]] != 0) {
        path[used++] = current;
        current = ancestor[current];
    }
    while (used > 0) {
        current = path[--used];
        int parent = ancestor[current];
        if (semi[label[parent]] < semi[label[current]]) label[current] = label[parent];
        ancestor[current] = ancestor[parent];
    }
    return label[vertex];
}

int64_t lengauer_tarjan_dominator_tree(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > LT_MAX_INPUT) return -1;
    int64_t nv = input[0], root_value = input[1], me = input[2];
    if (nv < 1 || nv > LT_MAX_V || root_value < 0 || root_value >= nv ||
        me < 0 || me > LT_MAX_E) return -1;
    int n = (int)nv, root = (int)root_value, m = (int)me;
    if (length != 3 + 2 * (size_t)m) return -1;

    uint64_t outmask[LT_MAX_V] = {0};
    int out_head[LT_MAX_V], edge_source[LT_MAX_E], edge_target[LT_MAX_E], out_next[LT_MAX_E];
    int pred_head[LT_MAX_V + 1], pred_next[LT_MAX_E];
    int dfs_number[LT_MAX_V] = {0}, vertex_at[LT_MAX_V + 1] = {0};
    int parent[LT_MAX_V + 1] = {0}, semi[LT_MAX_V + 1] = {0};
    int ancestor[LT_MAX_V + 1] = {0}, label[LT_MAX_V + 1] = {0};
    int immediate[LT_MAX_V + 1] = {0}, bucket_head[LT_MAX_V + 1];
    int bucket_next[LT_MAX_V + 1] = {0};
    int node_stack[LT_MAX_V], edge_stack[LT_MAX_V], eval_path[LT_MAX_V + 1];
    uint8_t staged[LT_MAX_V];
    for (int v = 0; v < n; ++v) out_head[v] = -1;
    for (int v = 0; v <= LT_MAX_V; ++v) pred_head[v] = bucket_head[v] = -1;

    int edge_count = 0;
    for (int i = 0; i < m; ++i) {
        int64_t source_value = input[3 + 2 * i], target_value = input[4 + 2 * i];
        if (source_value < 0 || source_value >= nv || target_value < 0 || target_value >= nv) return -1;
        int source = (int)source_value, target = (int)target_value;
        uint64_t bit = UINT64_C(1) << target;
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
        int frame = top - 1, current = node_stack[frame], edge = edge_stack[frame];
        if (edge == -1) { --top; continue; }
        edge_stack[frame] = out_next[edge];
        int target = edge_target[edge];
        if (dfs_number[target] == 0) {
            int number = ++dfs_count;
            dfs_number[target] = number;
            vertex_at[number] = target;
            parent[number] = dfs_number[current];
            node_stack[top] = target;
            edge_stack[top] = out_head[target];
            ++top;
        }
    }

    for (int edge = 0; edge < edge_count; ++edge) {
        int source_number = dfs_number[edge_source[edge]];
        int target_number = dfs_number[edge_target[edge]];
        if (source_number != 0 && target_number != 0) {
            pred_next[edge] = pred_head[target_number];
            pred_head[target_number] = edge;
        }
    }
    for (int v = 1; v <= dfs_count; ++v) semi[v] = label[v] = v;

    for (int w = dfs_count; w >= 2; --w) {
        for (int edge = pred_head[w]; edge != -1; edge = pred_next[edge]) {
            int predecessor = dfs_number[edge_source[edge]];
            int representative = lt_eval(predecessor, ancestor, label, semi, eval_path);
            if (semi[representative] < semi[w]) semi[w] = semi[representative];
        }
        bucket_next[w] = bucket_head[semi[w]];
        bucket_head[semi[w]] = w;
        ancestor[w] = parent[w];

        int owner = parent[w], member = bucket_head[owner];
        bucket_head[owner] = -1;
        while (member != -1) {
            int next = bucket_next[member];
            int representative = lt_eval(member, ancestor, label, semi, eval_path);
            immediate[member] = semi[representative] < semi[member] ? representative : owner;
            member = next;
        }
    }
    for (int w = 2; w <= dfs_count; ++w)
        if (immediate[w] != semi[w]) immediate[w] = immediate[immediate[w]];
    immediate[1] = 1;

    for (int v = 0; v < n; ++v) {
        int number = dfs_number[v];
        staged[v] = number == 0 ? UINT8_MAX : (uint8_t)vertex_at[immediate[number]];
    }
    if (output == NULL || capacity < (size_t)n) return -2;
    for (int v = 0; v < n; ++v) output[v] = staged[v];
    return n;
}
