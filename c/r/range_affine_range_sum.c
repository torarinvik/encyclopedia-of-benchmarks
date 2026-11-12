#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_LENGTH 64u
#define MAX_OPERATIONS 64u
#define MAX_TREE_NODES 256u
#define MAX_PARSEABLE_INPUT_VALUES 387u

static int64_t reduce(int64_t value)
{
    return value % MODULUS;
}

static void apply_node(int64_t *sum, int64_t *lazy_mul, int64_t *lazy_add,
                       size_t node, size_t segment_length, int64_t multiplier,
                       int64_t offset)
{
    sum[node] = reduce(multiplier * sum[node] + offset * (int64_t)segment_length);
    lazy_mul[node] = reduce(multiplier * lazy_mul[node]);
    lazy_add[node] = reduce(multiplier * lazy_add[node] + offset);
}

static void push(int64_t *sum, int64_t *lazy_mul, int64_t *lazy_add,
                 size_t node, size_t left, size_t right)
{
    if (right - left <= 1u || (lazy_mul[node] == 1 && lazy_add[node] == 0)) return;
    const size_t middle = left + (right - left) / 2u;
    apply_node(sum, lazy_mul, lazy_add, node * 2u, middle - left,
               lazy_mul[node], lazy_add[node]);
    apply_node(sum, lazy_mul, lazy_add, node * 2u + 1u, right - middle,
               lazy_mul[node], lazy_add[node]);
    lazy_mul[node] = 1;
    lazy_add[node] = 0;
}

static void build(int64_t *sum, const int64_t *values, size_t node,
                  size_t left, size_t right)
{
    if (right - left == 1u) {
        sum[node] = values[left];
        return;
    }
    const size_t middle = left + (right - left) / 2u;
    build(sum, values, node * 2u, left, middle);
    build(sum, values, node * 2u + 1u, middle, right);
    sum[node] = reduce(sum[node * 2u] + sum[node * 2u + 1u]);
}

static void update(int64_t *sum, int64_t *lazy_mul, int64_t *lazy_add,
                   size_t query_left, size_t query_right, size_t node,
                   size_t left, size_t right, int64_t multiplier, int64_t offset)
{
    if (query_left <= left && right <= query_right) {
        apply_node(sum, lazy_mul, lazy_add, node, right - left, multiplier, offset);
        return;
    }
    if (query_right <= left || right <= query_left) return;
    push(sum, lazy_mul, lazy_add, node, left, right);
    const size_t middle = left + (right - left) / 2u;
    update(sum, lazy_mul, lazy_add, query_left, query_right, node * 2u,
           left, middle, multiplier, offset);
    update(sum, lazy_mul, lazy_add, query_left, query_right, node * 2u + 1u,
           middle, right, multiplier, offset);
    sum[node] = reduce(sum[node * 2u] + sum[node * 2u + 1u]);
}

static int64_t query(int64_t *sum, int64_t *lazy_mul, int64_t *lazy_add,
                     size_t query_left, size_t query_right, size_t node,
                     size_t left, size_t right)
{
    if (query_left <= left && right <= query_right) return sum[node];
    if (query_right <= left || right <= query_left) return 0;
    push(sum, lazy_mul, lazy_add, node, left, right);
    const size_t middle = left + (right - left) / 2u;
    return reduce(query(sum, lazy_mul, lazy_add, query_left, query_right,
                        node * 2u, left, middle) +
                  query(sum, lazy_mul, lazy_add, query_left, query_right,
                        node * 2u + 1u, middle, right));
}

int64_t range_affine_range_sum_benchmark(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2u || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > (int64_t)MAX_LENGTH) return -1;
    const size_t n = (size_t)input[0];
    if (length < n + 2u) return -1;
    int64_t values[MAX_LENGTH];
    for (size_t i = 0u; i < n; ++i) {
        if (input[i + 1u] < 0 || input[i + 1u] >= MODULUS) return -1;
        values[i] = input[i + 1u];
    }
    if (input[n + 1u] < 1 || input[n + 1u] > (int64_t)MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)input[n + 1u];
    int64_t sum[MAX_TREE_NODES] = {0};
    int64_t lazy_mul[MAX_TREE_NODES];
    int64_t lazy_add[MAX_TREE_NODES] = {0};
    for (size_t i = 0u; i < MAX_TREE_NODES; ++i) lazy_mul[i] = 1;
    build(sum, values, 1u, 0u, n);

    size_t cursor = n + 2u;
    int64_t checksum = 0;
    for (size_t operation = 0u; operation < operation_count; ++operation) {
        if (cursor >= length) return -1;
        const int64_t opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor + 4u > length) return -1;
            const int64_t left_value = input[cursor++];
            const int64_t right_value = input[cursor++];
            const int64_t multiplier = input[cursor++];
            const int64_t offset = input[cursor++];
            if (left_value < 0 || left_value >= right_value || right_value > (int64_t)n ||
                multiplier < 1 || multiplier >= MODULUS || offset < 0 || offset >= MODULUS)
                return -1;
            update(sum, lazy_mul, lazy_add, (size_t)left_value, (size_t)right_value,
                   1u, 0u, n, multiplier, offset);
        } else if (opcode == 1) {
            if (cursor + 2u > length) return -1;
            const int64_t left_value = input[cursor++];
            const int64_t right_value = input[cursor++];
            if (left_value < 0 || left_value >= right_value || right_value > (int64_t)n)
                return -1;
            const int64_t result = query(sum, lazy_mul, lazy_add,
                (size_t)left_value, (size_t)right_value, 1u, 0u, n);
            checksum += (int64_t)(operation + 1u) * (result + MODULUS);
        } else {
            return -1;
        }
    }
    return cursor == length ? checksum : -1;
}
