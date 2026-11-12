#include <stddef.h>
#include <stdint.h>

#define MAX_Q 64
#define MAX_BITS 30
#define MAX_NODES (1 + MAX_BITS * MAX_Q)
#define MAX_INPUT_VALUES (1 + 2 * MAX_Q)

static int32_t find_or_create_child(int32_t children[MAX_NODES][2],
    int32_t *node_count, int32_t node, uint32_t bit) {
    int32_t child = children[node][bit];
    if (child < 0) {
        child = (*node_count)++;
        children[child][0] = -1;
        children[child][1] = -1;
        children[node][bit] = child;
    }
    return child;
}

static void insert_value(int32_t children[MAX_NODES][2], int32_t count[MAX_NODES],
    int32_t *node_count, uint32_t value) {
    int32_t path[MAX_BITS + 1];
    int32_t node = 0;
    path[0] = node;
    for (int bit = MAX_BITS - 1; bit >= 0; --bit) {
        const uint32_t direction = (value >> bit) & 1u;
        node = find_or_create_child(children, node_count, node, direction);
        path[MAX_BITS - bit] = node;
    }
    if (count[node] != 0) return;
    for (size_t depth = 0; depth <= MAX_BITS; ++depth) ++count[path[depth]];
}

static void remove_value(int32_t children[MAX_NODES][2], int32_t count[MAX_NODES],
    uint32_t value) {
    int32_t path[MAX_BITS + 1];
    int32_t node = 0;
    path[0] = node;
    for (int bit = MAX_BITS - 1; bit >= 0; --bit) {
        const uint32_t direction = (value >> bit) & 1u;
        node = children[node][direction];
        if (node < 0) return;
        path[MAX_BITS - bit] = node;
    }
    if (count[node] == 0) return;
    for (size_t depth = 0; depth <= MAX_BITS; ++depth) --count[path[depth]];
}

static uint32_t minimum_xor(int32_t children[MAX_NODES][2],
    const int32_t count[MAX_NODES], uint32_t value) {
    int32_t node = 0;
    uint32_t result = 0;
    for (int bit = MAX_BITS - 1; bit >= 0; --bit) {
        const uint32_t preferred = (value >> bit) & 1u;
        int32_t child = children[node][preferred];
        if (child >= 0 && count[child] > 0) {
            node = child;
        } else {
            result |= 1u << bit;
            node = children[node][preferred ^ 1u];
        }
    }
    return result;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t set_xor_min(const int64_t *input, size_t length,
                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_VALUES) return -1;
    const int64_t q_value = input[0];
    if (q_value < 1 || q_value > MAX_Q || length != 1 + 2 * (size_t)q_value) return -1;
    const size_t q = (size_t)q_value;
    for (size_t operation = 0; operation < q; ++operation) {
        const size_t offset = 1 + 2 * operation;
        if (input[offset] < 0 || input[offset] > 2 ||
            input[offset + 1] < 0 || input[offset + 1] >= (INT64_C(1) << MAX_BITS)) return -1;
    }

    int32_t children[MAX_NODES][2];
    int32_t count[MAX_NODES] = {0};
    children[0][0] = -1;
    children[0][1] = -1;
    int32_t node_count = 1;
    int64_t answer[MAX_Q];
    size_t answer_count = 0;
    for (size_t operation = 0; operation < q; ++operation) {
        const size_t offset = 1 + 2 * operation;
        const int64_t kind = input[offset];
        const uint32_t value = (uint32_t)input[offset + 1];
        if (kind == 0) {
            insert_value(children, count, &node_count, value);
        } else if (kind == 1) {
            remove_value(children, count, value);
        } else {
            if (count[0] == 0) return -1;
            answer[answer_count++] = (int64_t)minimum_xor(children, count, value);
        }
    }

    const size_t required = 8 * answer_count;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < answer_count; ++index)
        store_i64_le(output, 8 * index, answer[index]);
    return (int64_t)required;
}
