/* Adapted from cp-algorithms Sqrt Tree; CC BY-SA 4.0, see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 256
#define MAX_QUERIES 256
#define MAX_LEVELS 16
#define MAX_NODES (2 * MAX_ITEMS)
#define MAX_BETWEEN (2 * MAX_ITEMS)
#define MAX_INPUT_VALUES (2 + MAX_ITEMS + 2 * MAX_QUERIES)
#define VALUE_LIMIT INT64_C(1000000000)

typedef struct {
    const int64_t *values;
    int64_t prefix[MAX_LEVELS * MAX_ITEMS];
    int64_t suffix[MAX_LEVELS * MAX_ITEMS];
    int64_t between[MAX_LEVELS * MAX_BETWEEN];
    size_t used_values[MAX_LEVELS];
    size_t used_between[MAX_LEVELS];
    size_t left[MAX_NODES];
    size_t right[MAX_NODES];
    size_t depth[MAX_NODES];
    size_t value_offset[MAX_NODES];
    size_t between_offset[MAX_NODES];
    size_t block_size[MAX_NODES];
    size_t block_count[MAX_NODES];
    size_t child_start[MAX_NODES];
    size_t children[MAX_NODES];
    size_t node_count;
    size_t child_count;
} SqrtTreeState;

static int64_t min_i64(int64_t left, int64_t right)
{
    return left < right ? left : right;
}

static size_t create_node(SqrtTreeState *state, size_t left, size_t right, size_t depth)
{
    const size_t node = state->node_count++;
    state->left[node] = left;
    state->right[node] = right;
    state->depth[node] = depth;
    return node;
}

static void build_node(SqrtTreeState *state, size_t node)
{
    const size_t left = state->left[node];
    const size_t right = state->right[node];
    const size_t length = right - left;
    const size_t depth = state->depth[node];
    if (length <= 2) return;

    size_t block_size = 1;
    while (block_size * block_size < length) ++block_size;
    const size_t block_count = (length + block_size - 1) / block_size;
    const size_t value_offset = state->used_values[depth];
    const size_t between_offset = state->used_between[depth];
    state->value_offset[node] = value_offset;
    state->between_offset[node] = between_offset;
    state->block_size[node] = block_size;
    state->block_count[node] = block_count;
    state->used_values[depth] += length;
    state->used_between[depth] += block_count * block_count;

    int64_t block_min[MAX_ITEMS];
    for (size_t block = 0; block < block_count; ++block) {
        const size_t start = left + block * block_size;
        size_t end = start + block_size;
        if (end > right) end = right;
        const size_t first = value_offset + start - left;
        state->prefix[depth * MAX_ITEMS + first] = state->values[start];
        for (size_t index = start + 1; index < end; ++index) {
            const size_t slot = value_offset + index - left;
            state->prefix[depth * MAX_ITEMS + slot] =
                min_i64(state->prefix[depth * MAX_ITEMS + slot - 1], state->values[index]);
        }
        const size_t last = value_offset + end - 1 - left;
        state->suffix[depth * MAX_ITEMS + last] = state->values[end - 1];
        for (size_t index = end - 1; index > start; --index) {
            const size_t slot = value_offset + index - 1 - left;
            state->suffix[depth * MAX_ITEMS + slot] =
                min_i64(state->values[index - 1], state->suffix[depth * MAX_ITEMS + slot + 1]);
        }
        block_min[block] = state->prefix[depth * MAX_ITEMS + last];
    }

    for (size_t first = 0; first < block_count; ++first) {
        int64_t aggregate = block_min[first];
        for (size_t last = first; last < block_count; ++last) {
            if (last != first) aggregate = min_i64(aggregate, block_min[last]);
            state->between[depth * MAX_BETWEEN + between_offset + first * block_count + last] = aggregate;
        }
    }

    const size_t child_start = state->child_count;
    state->child_start[node] = child_start;
    for (size_t block = 0; block < block_count; ++block) {
        const size_t start = left + block * block_size;
        size_t end = start + block_size;
        if (end > right) end = right;
        const size_t child = create_node(state, start, end, depth + 1);
        state->children[state->child_count++] = child;
    }
    for (size_t block = 0; block < block_count; ++block) {
        build_node(state, state->children[child_start + block]);
    }
}

static int64_t query_node(const SqrtTreeState *state, size_t node, size_t left, size_t right)
{
    const size_t node_left = state->left[node];
    const size_t node_right = state->right[node];
    if (node_right - node_left <= 2) {
        int64_t answer = state->values[left];
        for (size_t index = left + 1; index <= right; ++index)
            answer = min_i64(answer, state->values[index]);
        return answer;
    }
    const size_t block_size = state->block_size[node];
    const size_t left_block = (left - node_left) / block_size;
    const size_t right_block = (right - node_left) / block_size;
    if (left_block == right_block)
        return query_node(state, state->children[state->child_start[node] + left_block], left, right);

    const size_t depth = state->depth[node];
    const size_t offset = state->value_offset[node];
    int64_t answer = state->suffix[depth * MAX_ITEMS + offset + left - node_left];
    if (left_block + 1 < right_block) {
        const size_t count = state->block_count[node];
        const size_t middle = state->between_offset[node] +
            (left_block + 1) * count + right_block - 1;
        answer = min_i64(answer, state->between[depth * MAX_BETWEEN + middle]);
    }
    answer = min_i64(answer, state->prefix[depth * MAX_ITEMS + offset + right - node_left]);
    return answer;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t sqrt_tree(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t item_count_value = input[0];
    const int64_t query_count_value = input[1];
    if (item_count_value < 1 || item_count_value > MAX_ITEMS ||
        query_count_value < 0 || query_count_value > MAX_QUERIES) return -1;
    const size_t item_count = (size_t)item_count_value;
    const size_t query_count = (size_t)query_count_value;
    if (length != 2 + item_count + 2 * query_count) return -1;
    for (size_t index = 0; index < item_count; ++index) {
        const int64_t value = input[2 + index];
        if (value < -VALUE_LIMIT || value > VALUE_LIMIT) return -1;
    }
    const size_t query_offset = 2 + item_count;
    for (size_t query = 0; query < query_count; ++query) {
        const int64_t left = input[query_offset + 2 * query];
        const int64_t right = input[query_offset + 2 * query + 1];
        if (left < 0 || right < left || right >= item_count_value) return -1;
    }
    const size_t required = 8 * query_count;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;

    SqrtTreeState state = {0};
    state.values = input + 2;
    const size_t root = create_node(&state, 0, item_count, 0);
    build_node(&state, root);
    for (size_t query = 0; query < query_count; ++query) {
        const size_t left = (size_t)input[query_offset + 2 * query];
        const size_t right = (size_t)input[query_offset + 2 * query + 1];
        store_i64_le(output, 8 * query, query_node(&state, root, left, right));
    }
    return (int64_t)required;
}
