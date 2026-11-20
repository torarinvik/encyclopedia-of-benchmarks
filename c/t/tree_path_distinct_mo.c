#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_Q 32
#define MAX_INPUT_VALUES (3 * MAX_N + 2 * MAX_Q)
typedef struct {
    size_t left, right, id, block, right_key;
} tree_path_query;

static size_t find_root(size_t parent[MAX_N], size_t item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

static void make_euler(size_t vertex, size_t previous, size_t n,
                       const uint8_t adjacent[MAX_N][MAX_N],
                       size_t parent[MAX_N], size_t depth[MAX_N],
                       size_t entry[MAX_N], size_t leave[MAX_N],
                       size_t euler[2 * MAX_N], size_t *clock) {
    parent[vertex] = previous;
    entry[vertex] = (*clock)++;
    euler[entry[vertex]] = vertex;
    for (size_t next = 0; next < n; ++next) {
        if (adjacent[vertex][next] && next != previous) {
            depth[next] = depth[vertex] + 1;
            make_euler(next, vertex, n, adjacent, parent, depth,
                       entry, leave, euler, clock);
        }
    }
    leave[vertex] = (*clock)++;
    euler[leave[vertex]] = vertex;
}

static size_t lowest_common_ancestor(size_t a, size_t b,
                                     const size_t parent[MAX_N],
                                     const size_t depth[MAX_N]) {
    while (depth[a] > depth[b]) a = parent[a];
    while (depth[b] > depth[a]) b = parent[b];
    while (a != b) {
        a = parent[a];
        b = parent[b];
    }
    return a;
}

static int query_less(tree_path_query left, tree_path_query right) {
    if (left.block != right.block) return left.block < right.block;
    if (left.right_key != right.right_key) return left.right_key < right.right_key;
    return left.id < right.id;
}

static void sift_down(tree_path_query values[MAX_Q], size_t root, size_t end) {
    while (root * 2 + 1 < end) {
        size_t child = root * 2 + 1;
        size_t largest = root;
        if (query_less(values[largest], values[child])) largest = child;
        if (child + 1 < end && query_less(values[largest], values[child + 1]))
            largest = child + 1;
        if (largest == root) return;
        const tree_path_query temporary = values[root];
        values[root] = values[largest];
        values[largest] = temporary;
        root = largest;
    }
}

static void sort_queries(tree_path_query values[MAX_Q], size_t count) {
    size_t start = count / 2;
    while (start > 0) {
        --start;
        sift_down(values, start, count);
    }
    size_t end = count;
    while (end > 1) {
        --end;
        const tree_path_query temporary = values[0];
        values[0] = values[end];
        values[end] = temporary;
        sift_down(values, 0, end);
    }
}

static void toggle_vertex(size_t vertex, const size_t color_id[MAX_N],
                          size_t color_count[MAX_N], uint8_t active[MAX_N],
                          size_t *distinct) {
    const size_t color = color_id[vertex];
    if (active[vertex]) {
        active[vertex] = 0;
        if (--color_count[color] == 0) --*distinct;
    } else {
        active[vertex] = 1;
        if (color_count[color]++ == 0) ++*distinct;
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tree_path_distinct_mo(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_VALUES + 1) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 3 * n + 2 * q) return -1;

    int64_t colors[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) colors[vertex] = input[2 + vertex];
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    size_t dsu_parent[MAX_N], dsu_size[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    size_t offset = 2 + n;
    for (size_t edge = 0; edge + 1 < n; ++edge) {
        const int64_t u_value = input[offset++], v_value = input[offset++];
        if (u_value < 0 || u_value >= n_value || v_value < 0 ||
            v_value >= n_value || u_value == v_value) return -1;
        const size_t u = (size_t)u_value, v = (size_t)v_value;
        size_t root_u = find_root(dsu_parent, u), root_v = find_root(dsu_parent, v);
        if (root_u == root_v) return -1;
        if (dsu_size[root_u] < dsu_size[root_v]) {
            const size_t temporary = root_u;
            root_u = root_v;
            root_v = temporary;
        }
        dsu_parent[root_v] = root_u;
        dsu_size[root_u] += dsu_size[root_v];
        adjacent[u][v] = adjacent[v][u] = 1;
    }

    int64_t query_u[MAX_Q], query_v[MAX_Q];
    for (size_t index = 0; index < q; ++index) {
        query_u[index] = input[offset++];
        query_v[index] = input[offset++];
        if (query_u[index] < 0 || query_u[index] >= n_value ||
            query_v[index] < 0 || query_v[index] >= n_value) return -1;
    }

    size_t color_id[MAX_N], color_first[MAX_N], distinct_colors = 0;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        size_t rank = 0;
        while (rank < distinct_colors && colors[color_first[rank]] != colors[vertex]) ++rank;
        if (rank == distinct_colors) color_first[distinct_colors++] = vertex;
        color_id[vertex] = rank;
    }

    size_t parent[MAX_N] = {0}, depth[MAX_N] = {0};
    size_t entry[MAX_N] = {0}, leave[MAX_N] = {0}, euler[2 * MAX_N] = {0};
    size_t euler_clock = 0;
    make_euler(0, n, n, adjacent, parent, depth, entry, leave, euler, &euler_clock);

    tree_path_query queries[MAX_Q];
    size_t block_size = 1;
    while ((block_size + 1) * (block_size + 1) <= 2 * n) ++block_size;
    for (size_t index = 0; index < q; ++index) {
        size_t u = (size_t)query_u[index], v = (size_t)query_v[index];
        if (entry[u] > entry[v]) {
            const size_t temporary = u;
            u = v;
            v = temporary;
        }
        const size_t ancestor = lowest_common_ancestor(u, v, parent, depth);
        const size_t left = ancestor == u ? entry[u] : leave[u];
        queries[index].left = left;
        queries[index].right = entry[v];
        queries[index].id = index;
        queries[index].block = left / block_size;
        queries[index].right_key = (queries[index].block & 1)
            ? 2 * n - 1 - entry[v] : entry[v];
    }
    sort_queries(queries, q);

    size_t color_count[MAX_N] = {0}, answers[MAX_Q] = {0};
    uint8_t active[MAX_N] = {0};
    size_t distinct = 0;
    int left = 0, right = -1;
    for (size_t index = 0; index < q; ++index) {
        const tree_path_query query = queries[index];
        while (left > (int)query.left) {
            --left;
            toggle_vertex(euler[left], color_id, color_count, active, &distinct);
        }
        while (right < (int)query.right) {
            ++right;
            toggle_vertex(euler[right], color_id, color_count, active, &distinct);
        }
        while (left < (int)query.left) {
            toggle_vertex(euler[left], color_id, color_count, active, &distinct);
            ++left;
        }
        while (right > (int)query.right) {
            toggle_vertex(euler[right], color_id, color_count, active, &distinct);
            --right;
        }
        const size_t u = (size_t)query_u[query.id], v = (size_t)query_v[query.id];
        const size_t ancestor = lowest_common_ancestor(u, v, parent, depth);
        /* The interval excludes the LCA exactly when the endpoints lie in
           separate child subtrees; ancestor queries already include it. */
        if (ancestor != u && ancestor != v) {
            toggle_vertex(ancestor, color_id, color_count, active, &distinct);
            answers[query.id] = distinct;
            toggle_vertex(ancestor, color_id, color_count, active, &distinct);
        } else {
            answers[query.id] = distinct;
        }
    }

    const size_t required = 8 * q;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < q; ++index)
        store_i64_le(output, 8 * index, (int64_t)answers[index]);
    return (int64_t)required;
}
