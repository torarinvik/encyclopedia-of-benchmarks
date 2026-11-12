#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 64
#define MODULUS INT64_C(998244353)
#define MAX_INPUT_VALUES (4 * MAX_N + 4 * MAX_Q)

typedef struct { int64_t a, b; } affine;
typedef struct { affine forward, backward; } aggregate;

static affine identity(void) { return (affine){1, 0}; }

static affine compose(affine after, affine before) {
    return (affine){
        (after.a * before.a) % MODULUS,
        (after.a * before.b + after.b) % MODULUS,
    };
}

static aggregate identity_aggregate(void) {
    const affine id = identity();
    return (aggregate){id, id};
}

static aggregate combine(aggregate left, aggregate right) {
    return (aggregate){compose(right.forward, left.forward),
                       compose(left.backward, right.backward)};
}

static void update_leaf(aggregate tree[2 * MAX_N], size_t base,
                        size_t position, affine value) {
    size_t node = base + position;
    tree[node] = (aggregate){value, value};
    while (node > 1) {
        node >>= 1;
        tree[node] = combine(tree[node << 1], tree[(node << 1) | 1]);
    }
}

static aggregate range_query(const aggregate tree[2 * MAX_N], size_t base,
                             size_t left, size_t right) {
    aggregate prefix = identity_aggregate(), suffix = identity_aggregate();
    left += base;
    right += base;
    while (left < right) {
        if (left & 1U) prefix = combine(prefix, tree[left++]);
        if (right & 1U) suffix = combine(tree[--right], suffix);
        left >>= 1;
        right >>= 1;
    }
    return combine(prefix, suffix);
}

static size_t find_root(size_t parent[MAX_N], size_t item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

static affine path_composition(const aggregate tree[2 * MAX_N], size_t base,
    const size_t parent[MAX_N], const size_t depth[MAX_N],
    const size_t head[MAX_N], const size_t position[MAX_N], size_t from, size_t to) {
    affine left = identity(), right = identity();
    while (head[from] != head[to]) {
        if (depth[head[from]] >= depth[head[to]]) {
            const aggregate part = range_query(tree, base, position[head[from]], position[from] + 1);
            left = compose(part.backward, left);
            from = parent[head[from]];
        } else {
            const aggregate part = range_query(tree, base, position[head[to]], position[to] + 1);
            right = compose(right, part.forward);
            to = parent[head[to]];
        }
    }
    if (depth[from] >= depth[to]) {
        const aggregate part = range_query(tree, base, position[to], position[from] + 1);
        left = compose(part.backward, left);
    } else {
        const aggregate part = range_query(tree, base, position[from], position[to] + 1);
        right = compose(right, part.forward);
    }
    return compose(right, left);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t vertex_set_path_composite(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 8 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 4 * n + 4 * q) return -1;

    affine values[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        const int64_t a = input[2 + 2 * vertex], b = input[3 + 2 * vertex];
        if (a < 1 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
        values[vertex] = (affine){a, b};
    }

    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    size_t dsu_parent[MAX_N], dsu_size[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    const size_t edge_start = 2 + 2 * n;
    for (size_t edge = 0; edge + 1 < n; ++edge) {
        const size_t offset = edge_start + 2 * edge;
        const int64_t left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        const size_t left = (size_t)left_value, right = (size_t)right_value;
        size_t root_left = find_root(dsu_parent, left), root_right = find_root(dsu_parent, right);
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

    const size_t operation_start = edge_start + 2 * (n - 1);
    for (size_t query = 0; query < q; ++query) {
        const size_t offset = operation_start + 4 * query;
        const int64_t kind = input[offset], first = input[offset + 1];
        const int64_t second = input[offset + 2], third = input[offset + 3];
        if (kind == 0) {
            if (first < 0 || first >= n_value || second < 1 || second >= MODULUS ||
                third < 0 || third >= MODULUS) return -1;
        } else if (kind == 1) {
            if (first < 0 || first >= n_value || second < 0 || second >= n_value ||
                third < 0 || third >= MODULUS) return -1;
        } else return -1;
    }

    size_t parent[MAX_N], depth[MAX_N], subtree[MAX_N], heavy[MAX_N], order[MAX_N];
    size_t stack[MAX_N], order_count = 0, top = 0;
    parent[0] = 0;
    depth[0] = 0;
    subtree[0] = 1;
    heavy[0] = MAX_N;
    stack[top++] = 0;
    order[order_count++] = 0;
    while (top > 0) {
        const size_t vertex = stack[--top];
        for (size_t neighbor = 0; neighbor < n; ++neighbor) {
            if (!adjacent[vertex][neighbor] || neighbor == parent[vertex]) continue;
            parent[neighbor] = vertex;
            depth[neighbor] = depth[vertex] + 1;
            subtree[neighbor] = 1;
            heavy[neighbor] = MAX_N;
            order[order_count++] = neighbor;
            stack[top++] = neighbor;
        }
    }
    for (size_t index = order_count; index > 1; --index) {
        const size_t vertex = order[index - 1], p = parent[vertex];
        subtree[p] += subtree[vertex];
        if (heavy[p] == MAX_N || subtree[vertex] > subtree[heavy[p]] ||
            (subtree[vertex] == subtree[heavy[p]] && vertex < heavy[p])) heavy[p] = vertex;
    }

    size_t head[MAX_N], position[MAX_N], chain_vertex[MAX_N], chain_head[MAX_N];
    size_t chain_count = 0, timer = 0;
    chain_vertex[chain_count] = 0;
    chain_head[chain_count++] = 0;
    while (chain_count > 0) {
        --chain_count;
        size_t vertex = chain_vertex[chain_count];
        const size_t current_head = chain_head[chain_count];
        while (vertex != MAX_N) {
            head[vertex] = current_head;
            position[vertex] = timer++;
            for (size_t child = 0; child < n; ++child) {
                if (adjacent[vertex][child] && parent[child] == vertex && child != heavy[vertex]) {
                    chain_vertex[chain_count] = child;
                    chain_head[chain_count++] = child;
                }
            }
            vertex = heavy[vertex];
        }
    }

    size_t base = 1;
    while (base < n) base <<= 1;
    aggregate tree[2 * MAX_N];
    for (size_t node = 0; node < 2 * base; ++node) tree[node] = identity_aggregate();
    for (size_t vertex = 0; vertex < n; ++vertex)
        update_leaf(tree, base, position[vertex], values[vertex]);

    int64_t answers[MAX_Q];
    size_t answer_count = 0;
    for (size_t query = 0; query < q; ++query) {
        const size_t offset = operation_start + 4 * query;
        const int64_t kind = input[offset];
        const size_t first = (size_t)input[offset + 1];
        const int64_t second = input[offset + 2], third = input[offset + 3];
        if (kind == 0) {
            values[first] = (affine){second, third};
            update_leaf(tree, base, position[first], values[first]);
        } else {
            const affine combined = path_composition(tree, base, parent, depth, head, position,
                first, (size_t)second);
            answers[answer_count++] = (combined.a * third + combined.b) % MODULUS;
        }
    }

    const size_t required = 8 * answer_count;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < answer_count; ++index)
        store_i64_le(output, 8 * index, answers[index]);
    return (int64_t)required;
}
