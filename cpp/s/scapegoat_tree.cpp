#include <cstddef>
#include <cstdint>

using std::int32_t;
using std::int64_t;
using std::size_t;
using std::uint8_t;
using std::uint64_t;

#define MAX_OPERATIONS 64
#define MAX_LIVE_KEYS 32
#define MAX_INPUT_LENGTH (1 + 2 * MAX_OPERATIONS)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_INPUT_LENGTH + 1)
#define MAX_OUTPUT_BYTES (8 * (2 + MAX_OPERATIONS + MAX_LIVE_KEYS))

typedef struct {
    int64_t key;
    int32_t left;
    int32_t right;
    bool active;
} Node;

static size_t subtree_size(const Node *nodes, int32_t root) {
    if (root < 0) return 0;
    return 1 + subtree_size(nodes, nodes[root].left) + subtree_size(nodes, nodes[root].right);
}

static size_t alpha_height(const Node *nodes, int32_t root) {
    size_t size = subtree_size(nodes, root);
    size_t height = 0;
    while (size > 1) {
        size >>= 1;
        ++height;
    }
    return height;
}

static void flatten(const Node *nodes, int32_t root, int32_t *order, size_t *length) {
    if (root < 0) return;
    flatten(nodes, nodes[root].left, order, length);
    order[(*length)++] = root;
    flatten(nodes, nodes[root].right, order, length);
}

static int32_t rebuild(Node *nodes, const int32_t *order, size_t start, size_t end) {
    if (start >= end) return -1;
    const size_t pivot = (start + end) / 2;
    const int32_t root = order[pivot];
    nodes[root].left = rebuild(nodes, order, start, pivot);
    nodes[root].right = rebuild(nodes, order, pivot + 1, end);
    return root;
}

static bool find_key(const Node *nodes, int32_t root, int64_t key) {
    while (root >= 0) {
        if (key == nodes[root].key) return true;
        root = key < nodes[root].key ? nodes[root].left : nodes[root].right;
    }
    return false;
}

static int32_t allocate_node(Node *nodes, int64_t key) {
    for (int32_t index = 0; index < MAX_LIVE_KEYS; ++index) {
        if (!nodes[index].active) {
            nodes[index].key = key;
            nodes[index].left = -1;
            nodes[index].right = -1;
            nodes[index].active = true;
            return index;
        }
    }
    return -1;
}

static bool insert_key(Node *nodes, int32_t *root, size_t *size, size_t *max_size, int64_t key) {
    if (*root < 0) {
        *root = allocate_node(nodes, key);
        if (*root < 0) return false;
        ++*size;
        if (*size > *max_size) *max_size = *size;
        return true;
    }

    int32_t path[MAX_LIVE_KEYS];
    size_t path_length = 0;
    int32_t current = *root;
    while (true) {
        path[path_length++] = current;
        if (key == nodes[current].key) return false;
        int32_t *child = key < nodes[current].key ? &nodes[current].left : &nodes[current].right;
        if (*child < 0) {
            *child = allocate_node(nodes, key);
            if (*child < 0) return false;
            break;
        }
        current = *child;
    }

    ++*size;
    if (*size > *max_size) *max_size = *size;
    if (path_length > alpha_height(nodes, *root)) {
        size_t depth = 1;
        int32_t scapegoat = -1;
        int32_t parent = -1;
        while (path_length > 0) {
            const int32_t candidate = path[--path_length];
            if (depth > alpha_height(nodes, candidate)) {
                scapegoat = candidate;
                if (path_length > 0) parent = path[--path_length];
                break;
            }
            ++depth;
        }
        int32_t order[MAX_LIVE_KEYS];
        size_t order_length = 0;
        flatten(nodes, scapegoat, order, &order_length);
        const int32_t rebuilt = rebuild(nodes, order, 0, order_length);
        if (parent < 0) *root = rebuilt;
        else if (nodes[parent].key < nodes[rebuilt].key) nodes[parent].right = rebuilt;
        else nodes[parent].left = rebuilt;
    }
    return true;
}

static bool delete_key(Node *nodes, int32_t *root, size_t *size, size_t *max_size, int64_t key) {
    int32_t parent = -1;
    int32_t node = *root;
    while (node >= 0 && nodes[node].key != key) {
        parent = node;
        node = key < nodes[node].key ? nodes[node].left : nodes[node].right;
    }
    if (node < 0) return false;

    if (nodes[node].left >= 0 && nodes[node].right >= 0) {
        int32_t predecessor_parent = node;
        int32_t predecessor = nodes[node].left;
        while (nodes[predecessor].right >= 0) {
            predecessor_parent = predecessor;
            predecessor = nodes[predecessor].right;
        }
        nodes[node].key = nodes[predecessor].key;
        const int32_t replacement = nodes[predecessor].left;
        if (predecessor_parent == node) nodes[node].left = replacement;
        else nodes[predecessor_parent].right = replacement;
        nodes[predecessor].active = false;
        nodes[predecessor].left = -1;
        nodes[predecessor].right = -1;
    } else {
        const int32_t replacement = nodes[node].left >= 0 ? nodes[node].left : nodes[node].right;
        if (parent < 0) *root = replacement;
        else if (nodes[parent].left == node) nodes[parent].left = replacement;
        else nodes[parent].right = replacement;
        nodes[node].active = false;
        nodes[node].left = -1;
        nodes[node].right = -1;
    }

    --*size;
    if (*root >= 0 && 2 * *size < *max_size) {
        int32_t order[MAX_LIVE_KEYS];
        size_t order_length = 0;
        flatten(nodes, *root, order, &order_length);
        *root = rebuild(nodes, order, 0, order_length);
        *max_size = *size;
    }
    return true;
}

static bool root_weight_balanced(const Node *nodes, int32_t root) {
    if (root < 0) return true;
    const size_t total = subtree_size(nodes, root);
    return 2 * subtree_size(nodes, nodes[root].left) <= total &&
        2 * subtree_size(nodes, nodes[root].right) <= total;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255);
        bits >>= 8;
    }
}

extern "C" int64_t scapegoat_tree(const int64_t *input, size_t length,
                       uint8_t *output, size_t capacity) {
    if (input == nullptr || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)operation_count_value;
    if (length != 1 + 2 * operation_count) return -1;

    int64_t active_keys[MAX_LIVE_KEYS];
    size_t active_count = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t offset = 1 + 2 * operation;
        const int64_t opcode = input[offset];
        const int64_t key = input[offset + 1];
        if (key < INT32_MIN || key > INT32_MAX || opcode < 0 || opcode > 6) return -1;
        if (opcode >= 3 && key != 0) return -1;
        if (opcode == 0) {
            bool present = false;
            for (size_t i = 0; i < active_count; ++i) if (active_keys[i] == key) present = true;
            if (!present) {
                if (active_count == MAX_LIVE_KEYS) return -1;
                active_keys[active_count++] = key;
            }
        } else if (opcode == 2) {
            for (size_t i = 0; i < active_count; ++i) {
                if (active_keys[i] == key) {
                    for (size_t j = i; j + 1 < active_count; ++j) active_keys[j] = active_keys[j + 1];
                    --active_count;
                    break;
                }
            }
        } else if (opcode == 6) {
            active_count = 0;
        }
    }

    Node nodes[MAX_LIVE_KEYS] = {0};
    for (size_t i = 0; i < MAX_LIVE_KEYS; ++i) nodes[i].left = nodes[i].right = -1;
    int32_t root = -1;
    size_t size = 0;
    size_t max_size = 0;
    int64_t results[MAX_OPERATIONS] = {0};
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t offset = 1 + 2 * operation;
        const int64_t opcode = input[offset];
        const int64_t key = input[offset + 1];
        if (opcode == 0) results[operation] = insert_key(nodes, &root, &size, &max_size, key) ? 1 : 0;
        else if (opcode == 1) results[operation] = find_key(nodes, root, key) ? 1 : 0;
        else if (opcode == 2) results[operation] = delete_key(nodes, &root, &size, &max_size, key) ? 1 : 0;
        else if (opcode == 3) results[operation] = (int64_t)size;
        else if (opcode == 4) results[operation] = (int64_t)max_size;
        else if (opcode == 5) results[operation] = root_weight_balanced(nodes, root) ? 1 : 0;
        else {
            for (size_t i = 0; i < MAX_LIVE_KEYS; ++i) {
                nodes[i].active = false;
                nodes[i].left = nodes[i].right = -1;
            }
            root = -1;
            size = 0;
            max_size = 0;
            results[operation] = -2;
        }
    }

    const size_t output_bytes = (2 + operation_count + size) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    put_i64_le(staged, 0, (int64_t)operation_count);
    for (size_t operation = 0; operation < operation_count; ++operation)
        put_i64_le(staged, (1 + operation) * 8, results[operation]);
    put_i64_le(staged, (1 + operation_count) * 8, (int64_t)size);
    int32_t order[MAX_LIVE_KEYS];
    size_t order_length = 0;
    flatten(nodes, root, order, &order_length);
    for (size_t i = 0; i < order_length; ++i)
        put_i64_le(staged, (2 + operation_count + i) * 8, nodes[order[i]].key);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
