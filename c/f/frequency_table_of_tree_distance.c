#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_VALUES (1 + 2 * (MAX_N - 1))
#define MAX_OUTPUT_VALUES (MAX_N - 1)

typedef struct {
    size_t vertex;
    size_t parent;
    size_t depth;
} walk_item;

static size_t find_root(size_t parent[MAX_N], size_t item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

static void solve_component(size_t n, const uint8_t adjacent[MAX_N][MAX_N],
                            uint8_t removed[MAX_N], int64_t answer[MAX_N], size_t start) {
    size_t order[MAX_N], parent[MAX_N], subtree[MAX_N] = {0};
    size_t stack[MAX_N], order_count = 0, top = 0;
    stack[top++] = start;
    parent[start] = start;
    subtree[start] = 1;
    order[order_count++] = start;
    while (top > 0) {
        const size_t vertex = stack[--top];
        for (size_t neighbor = 0; neighbor < n; ++neighbor) {
            if (!adjacent[vertex][neighbor] || removed[neighbor] || neighbor == parent[vertex]) continue;
            parent[neighbor] = vertex;
            subtree[neighbor] = 1;
            order[order_count++] = neighbor;
            stack[top++] = neighbor;
        }
    }
    for (size_t position = order_count; position > 1; --position) {
        const size_t vertex = order[position - 1];
        subtree[parent[vertex]] += subtree[vertex];
    }

    size_t centroid = MAX_N;
    for (size_t position = 0; position < order_count; ++position) {
        const size_t vertex = order[position];
        size_t largest_part = order_count - subtree[vertex];
        for (size_t neighbor = 0; neighbor < n; ++neighbor) {
            if (adjacent[vertex][neighbor] && !removed[neighbor] && parent[neighbor] == vertex &&
                subtree[neighbor] > largest_part) largest_part = subtree[neighbor];
        }
        if (2 * largest_part <= order_count && (centroid == MAX_N || vertex < centroid))
            centroid = vertex;
    }

    int64_t frequency[MAX_N] = {0};
    size_t frequency_max = 0;
    frequency[0] = 1;
    removed[centroid] = 1;
    for (size_t child = 0; child < n; ++child) {
        if (!adjacent[centroid][child] || removed[child]) continue;
        size_t local_frequency[MAX_N] = {0};
        walk_item walk[MAX_N];
        size_t local_max = 0, walk_top = 0;
        walk[walk_top++] = (walk_item){child, centroid, 1};
        while (walk_top > 0) {
            const walk_item item = walk[--walk_top];
            ++local_frequency[item.depth];
            if (item.depth > local_max) local_max = item.depth;
            for (size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacent[item.vertex][neighbor] && !removed[neighbor] && neighbor != item.parent)
                    walk[walk_top++] = (walk_item){neighbor, item.vertex, item.depth + 1};
            }
        }
        for (size_t depth = 1; depth <= local_max; ++depth)
            for (size_t other = 0; other <= frequency_max && depth + other < n; ++other)
                answer[depth + other] += (int64_t)local_frequency[depth] * frequency[other];
        for (size_t depth = 1; depth <= local_max; ++depth)
            frequency[depth] += (int64_t)local_frequency[depth];
        if (local_max > frequency_max) frequency_max = local_max;
    }

    for (size_t child = 0; child < n; ++child)
        if (adjacent[centroid][child] && !removed[child])
            solve_component(n, adjacent, removed, answer, child);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t frequency_table_of_tree_distance(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + 2 * (n - 1)) return -1;

    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    size_t dsu_parent[MAX_N], dsu_size[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for (size_t edge = 0; edge + 1 < n; ++edge) {
        const size_t offset = 1 + 2 * edge;
        const int64_t left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        const size_t left = (size_t)left_value, right = (size_t)right_value;
        size_t root_left = find_root(dsu_parent, left);
        size_t root_right = find_root(dsu_parent, right);
        if (root_left == root_right) return -1;
        if (dsu_size[root_left] < dsu_size[root_right]) {
            const size_t temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        dsu_parent[root_right] = root_left;
        dsu_size[root_left] += dsu_size[root_right];
        adjacent[left][right] = adjacent[right][left] = 1;
    }

    uint8_t removed[MAX_N] = {0};
    int64_t answer[MAX_N] = {0};
    solve_component(n, adjacent, removed, answer, 0);
    const size_t required = 8 * (n - 1);
    if (output == NULL || capacity < required) return -2;
    for (size_t distance = 1; distance < n; ++distance)
        store_i64_le(output, 8 * (distance - 1), answer[distance]);
    return (int64_t)required;
}
