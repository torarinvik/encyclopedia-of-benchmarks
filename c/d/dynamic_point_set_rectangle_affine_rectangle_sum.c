#include <stddef.h>
#include <stdint.h>

#define MAX_N 32u
#define MAX_Q 32u
#define MAX_POINTS (MAX_N + MAX_Q)
#define MAX_TREE (4u * MAX_POINTS + 8u)
#define MAX_PARSEABLE_INPUT (2u + 3u * MAX_N + 7u * MAX_Q + 1u)
#define MOD INT64_C(998244353)
#define MAX_COORD INT64_C(1000000000)

typedef struct {
    int64_t kind, a, b, c, d, e, f;
} operation_t;

typedef struct {
    int64_t min_x, max_x, min_y, max_y;
    int64_t sum, lazy_a, lazy_b;
    size_t active;
} node_t;

static int point_less(size_t left, size_t right, const int64_t *xs,
                      const int64_t *ys, size_t axis)
{
    const int64_t first = axis == 0u ? xs[left] : ys[left];
    const int64_t second = axis == 0u ? xs[right] : ys[right];
    if (first != second) return first < second;
    const int64_t first_other = axis == 0u ? ys[left] : xs[left];
    const int64_t second_other = axis == 0u ? ys[right] : xs[right];
    if (first_other != second_other) return first_other < second_other;
    return left < right;
}

static void sort_points(size_t *order, size_t low, size_t high, size_t axis,
                        const int64_t *xs, const int64_t *ys)
{
    for (size_t i = low + 1u; i < high; ++i) {
        const size_t point = order[i];
        size_t j = i;
        while (j > low && point_less(point, order[j - 1u], xs, ys, axis)) {
            order[j] = order[j - 1u];
            --j;
        }
        order[j] = point;
    }
}

static int64_t build_tree(node_t *tree, size_t *order, size_t low, size_t high,
                          size_t index, size_t depth, size_t initial_n,
                          const int64_t *xs, const int64_t *ys,
                          const int64_t *weights, size_t *rank)
{
    node_t *node = &tree[index];
    node->lazy_a = 1;
    if (high - low == 1u) {
        const size_t point = order[low];
        node->min_x = node->max_x = xs[point];
        node->min_y = node->max_y = ys[point];
        node->active = point < initial_n ? 1u : 0u;
        node->sum = point < initial_n ? weights[point] : 0;
        rank[point] = low;
        return node->sum;
    }
    sort_points(order, low, high, depth & 1u, xs, ys);
    const size_t middle = low + (high - low) / 2u;
    build_tree(tree, order, low, middle, index * 2u, depth + 1u,
               initial_n, xs, ys, weights, rank);
    build_tree(tree, order, middle, high, index * 2u + 1u, depth + 1u,
               initial_n, xs, ys, weights, rank);
    const node_t *left = &tree[index * 2u];
    const node_t *right = &tree[index * 2u + 1u];
    node->min_x = left->min_x < right->min_x ? left->min_x : right->min_x;
    node->max_x = left->max_x > right->max_x ? left->max_x : right->max_x;
    node->min_y = left->min_y < right->min_y ? left->min_y : right->min_y;
    node->max_y = left->max_y > right->max_y ? left->max_y : right->max_y;
    node->active = left->active + right->active;
    node->sum = (left->sum + right->sum) % MOD;
    return node->sum;
}

static void apply_node(node_t *tree, size_t index, int64_t a, int64_t b)
{
    node_t *node = &tree[index];
    if (node->active == 0u) return;
    node->sum = (a * node->sum + b * (int64_t)node->active) % MOD;
    node->lazy_a = a * node->lazy_a % MOD;
    node->lazy_b = (a * node->lazy_b + b) % MOD;
}

static void push(node_t *tree, size_t index, size_t low, size_t high)
{
    node_t *node = &tree[index];
    if (high - low == 1u || (node->lazy_a == 1 && node->lazy_b == 0)) return;
    apply_node(tree, index * 2u, node->lazy_a, node->lazy_b);
    apply_node(tree, index * 2u + 1u, node->lazy_a, node->lazy_b);
    node->lazy_a = 1;
    node->lazy_b = 0;
}

static int disjoint(const node_t *node, int64_t left, int64_t down,
                    int64_t right, int64_t up)
{
    return node->max_x < left || node->min_x >= right ||
           node->max_y < down || node->min_y >= up;
}

static int covered(const node_t *node, int64_t left, int64_t down,
                   int64_t right, int64_t up)
{
    return left <= node->min_x && node->max_x < right &&
           down <= node->min_y && node->max_y < up;
}

static void pull(node_t *tree, size_t index)
{
    node_t *node = &tree[index];
    const node_t *left = &tree[index * 2u];
    const node_t *right = &tree[index * 2u + 1u];
    node->sum = (left->sum + right->sum) % MOD;
    node->active = left->active + right->active;
}

static int64_t rectangle_sum(node_t *tree, size_t index, size_t low, size_t high,
                             int64_t left, int64_t down, int64_t right, int64_t up)
{
    node_t *node = &tree[index];
    if (node->active == 0u || disjoint(node, left, down, right, up)) return 0;
    if (covered(node, left, down, right, up)) return node->sum;
    push(tree, index, low, high);
    const size_t middle = low + (high - low) / 2u;
    return (rectangle_sum(tree, index * 2u, low, middle,
                          left, down, right, up) +
            rectangle_sum(tree, index * 2u + 1u, middle, high,
                          left, down, right, up)) % MOD;
}

static void rectangle_affine(node_t *tree, size_t index, size_t low, size_t high,
                             int64_t left, int64_t down, int64_t right, int64_t up,
                             int64_t a, int64_t b)
{
    node_t *node = &tree[index];
    if (node->active == 0u || disjoint(node, left, down, right, up)) return;
    if (covered(node, left, down, right, up)) {
        apply_node(tree, index, a, b);
        return;
    }
    push(tree, index, low, high);
    const size_t middle = low + (high - low) / 2u;
    rectangle_affine(tree, index * 2u, low, middle,
                     left, down, right, up, a, b);
    rectangle_affine(tree, index * 2u + 1u, middle, high,
                     left, down, right, up, a, b);
    pull(tree, index);
}

static void set_point(node_t *tree, size_t index, size_t low, size_t high,
                      size_t target, int64_t weight)
{
    if (high - low == 1u) {
        tree[index].sum = weight;
        tree[index].active = 1u;
        tree[index].lazy_a = 1;
        tree[index].lazy_b = 0;
        return;
    }
    push(tree, index, low, high);
    const size_t middle = low + (high - low) / 2u;
    if (target < middle)
        set_point(tree, index * 2u, low, middle, target, weight);
    else
        set_point(tree, index * 2u + 1u, middle, high, target, weight);
    pull(tree, index);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0u; byte < 8u; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t dynamic_point_set_rectangle_affine_rectangle_sum(
        const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2u || length > MAX_PARSEABLE_INPUT) return -1;
    if (input[0] < 1 || input[0] > (int64_t)MAX_N ||
        input[1] < 1 || input[1] > (int64_t)MAX_Q) return -1;
    const size_t n = (size_t)input[0], q = (size_t)input[1];
    if (2u + 3u * n > length) return -1;

    int64_t xs[MAX_POINTS], ys[MAX_POINTS], weights[MAX_POINTS];
    operation_t operations[MAX_Q];
    size_t point_count = n, active_count = n, query_count = 0u;
    for (size_t i = 0u; i < n; ++i) {
        xs[i] = input[2u + 3u * i];
        ys[i] = input[3u + 3u * i];
        weights[i] = input[4u + 3u * i];
        if (xs[i] < 0 || xs[i] > MAX_COORD || ys[i] < 0 || ys[i] > MAX_COORD ||
            weights[i] < 0 || weights[i] >= MOD) return -1;
    }
    size_t cursor = 2u + 3u * n;
    for (size_t operation = 0u; operation < q; ++operation) {
        if (cursor >= length) return -1;
        const int64_t kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 3u > length || point_count >= MAX_POINTS) return -1;
            const int64_t x = input[cursor], y = input[cursor + 1u], weight = input[cursor + 2u];
            cursor += 3u;
            if (x < 0 || x > MAX_COORD || y < 0 || y > MAX_COORD || weight < 0 || weight >= MOD)
                return -1;
            xs[point_count] = x;
            ys[point_count] = y;
            operations[operation] = (operation_t){kind, (int64_t)point_count, weight, 0, 0, 0, 0};
            ++point_count;
            ++active_count;
        } else if (kind == 1) {
            if (cursor + 2u > length) return -1;
            const int64_t point = input[cursor], weight = input[cursor + 1u];
            cursor += 2u;
            if (point < 0 || point >= (int64_t)active_count || weight < 0 || weight >= MOD)
                return -1;
            operations[operation] = (operation_t){kind, point, weight, 0, 0, 0, 0};
        } else if (kind == 2 || kind == 3) {
            const size_t fields = kind == 2 ? 4u : 6u;
            if (cursor + fields > length) return -1;
            const int64_t left = input[cursor], down = input[cursor + 1u];
            const int64_t right = input[cursor + 2u], up = input[cursor + 3u];
            if (left < 0 || left >= right || right > MAX_COORD ||
                down < 0 || down >= up || up > MAX_COORD) return -1;
            if (kind == 2) {
                cursor += 4u;
                operations[operation] = (operation_t){kind, left, down, right, up, 0, 0};
                ++query_count;
            } else {
                const int64_t a = input[cursor + 4u], b = input[cursor + 5u];
                cursor += 6u;
                if (a < 0 || a >= MOD || b < 0 || b >= MOD) return -1;
                operations[operation] = (operation_t){kind, left, down, right, up, a, b};
            }
        } else return -1;
    }
    if (cursor != length) return -1;
    const size_t output_bytes = 8u * query_count;
    if (output_bytes > 0u && (output == NULL || capacity < output_bytes)) return -2;

    node_t tree[MAX_TREE] = {{0}};
    size_t order[MAX_POINTS], rank[MAX_POINTS];
    for (size_t i = 0u; i < point_count; ++i) order[i] = i;
    build_tree(tree, order, 0u, point_count, 1u, 0u, n, xs, ys, weights, rank);
    int64_t answers[MAX_Q];
    size_t answer_count = 0u;
    for (size_t i = 0u; i < q; ++i) {
        const operation_t op = operations[i];
        if (op.kind == 0 || op.kind == 1) {
            set_point(tree, 1u, 0u, point_count, rank[(size_t)op.a], op.b);
        } else if (op.kind == 2) {
            answers[answer_count++] = rectangle_sum(tree, 1u, 0u, point_count,
                op.a, op.b, op.c, op.d);
        } else {
            rectangle_affine(tree, 1u, 0u, point_count,
                op.a, op.b, op.c, op.d, op.e, op.f);
        }
    }
    for (size_t i = 0u; i < answer_count; ++i)
        store_i64_le(output, 8u * i, answers[i]);
    return (int64_t)output_bytes;
}
