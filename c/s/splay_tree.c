#include <stddef.h>
#include <stdint.h>

#define MAX_OPS 64u
#define MAX_KEYS 32u
#define MAX_INPUT 130u
#define MAX_OUTPUT 784u

typedef struct { int32_t key, left, right; } Node;

static int32_t rotate_right(Node *nodes, int32_t root) {
    int32_t child = nodes[root].left;
    nodes[root].left = nodes[child].right;
    nodes[child].right = root;
    return child;
}

static int32_t rotate_left(Node *nodes, int32_t root) {
    int32_t child = nodes[root].right;
    nodes[root].right = nodes[child].left;
    nodes[child].left = root;
    return child;
}

static int32_t splay(Node *nodes, int32_t root, int32_t key) {
    if (root < 0 || nodes[root].key == key) return root;
    if (key < nodes[root].key) {
        int32_t left = nodes[root].left;
        if (left < 0) return root;
        if (key < nodes[left].key) {
            nodes[left].left = splay(nodes, nodes[left].left, key);
            root = rotate_right(nodes, root);
        } else if (key > nodes[left].key) {
            nodes[left].right = splay(nodes, nodes[left].right, key);
            if (nodes[left].right >= 0) nodes[root].left = rotate_left(nodes, left);
        }
        return nodes[root].left < 0 ? root : rotate_right(nodes, root);
    }
    int32_t right = nodes[root].right;
    if (right < 0) return root;
    if (key > nodes[right].key) {
        nodes[right].right = splay(nodes, nodes[right].right, key);
        root = rotate_left(nodes, root);
    } else if (key < nodes[right].key) {
        nodes[right].left = splay(nodes, nodes[right].left, key);
        if (nodes[right].left >= 0) nodes[root].right = rotate_right(nodes, right);
    }
    return nodes[root].right < 0 ? root : rotate_left(nodes, root);
}

static void write_word(uint8_t *out, size_t *offset, int64_t word) {
    const uint64_t bits = (uint64_t)word;
    for (unsigned shift = 0; shift < 64; shift += 8) out[(*offset)++] = (uint8_t)(bits >> shift);
}

static void inorder(const Node *nodes, int32_t root, int64_t *keys, size_t *count) {
    if (root < 0) return;
    inorder(nodes, nodes[root].left, keys, count);
    keys[(*count)++] = nodes[root].key;
    inorder(nodes, nodes[root].right, keys, count);
}

int64_t splay_tree(const int64_t *input, size_t input_length, uint8_t *output, size_t capacity) {
    if (input == NULL || input_length == 0 || input_length > MAX_INPUT || input[0] < 0 || input[0] > (int64_t)MAX_OPS) return -1;
    const size_t op_count = (size_t)input[0];
    if (input_length != 1u + 2u * op_count) return -1;
    int64_t ops[MAX_OPS], keys[MAX_OPS], result_tags[MAX_OPS];
    int64_t live[MAX_KEYS];
    size_t live_count = 0, offset = 1;
    for (size_t i = 0; i < op_count; ++i) {
        const int64_t op = input[offset++], key = input[offset++];
        if ((op != 0 && op != 1 && op != 2) || key < INT32_MIN || key > INT32_MAX) return -1;
        ops[i] = op; keys[i] = key;
        size_t found = live_count;
        for (size_t j = 0; j < live_count; ++j) if (live[j] == key) { found = j; break; }
        if (op == 0) {
            if (found < live_count || live_count == MAX_KEYS) return -1;
            live[live_count++] = key;
        } else if (op == 2) {
            if (live_count == 0) return -1;
            if (found < live_count) { live[found] = live[--live_count]; }
        }
    }
    Node nodes[MAX_OPS];
    size_t node_count = 0;
    int32_t root = -1;
    for (size_t i = 0; i < op_count; ++i) {
        const int32_t key = (int32_t)keys[i];
        if (ops[i] == 0) {
            if (root < 0) {
                nodes[node_count] = (Node){key, -1, -1};
                root = (int32_t)node_count++;
            } else {
                root = splay(nodes, root, key);
                nodes[node_count] = (Node){key, -1, -1};
                const int32_t fresh = (int32_t)node_count++;
                if (key < nodes[root].key) { nodes[fresh].left = nodes[root].left; nodes[fresh].right = root; nodes[root].left = -1; }
                else { nodes[fresh].right = nodes[root].right; nodes[fresh].left = root; nodes[root].right = -1; }
                root = fresh;
            }
            result_tags[i] = -2;
        } else if (ops[i] == 1) {
            root = splay(nodes, root, key);
            result_tags[i] = root >= 0 && nodes[root].key == key ? 1 : 0;
        } else {
            root = splay(nodes, root, key);
            result_tags[i] = -3;
            if (nodes[root].key == key) {
                const int32_t left = nodes[root].left, right = nodes[root].right;
                if (left < 0) root = right;
                else {
                    int32_t joined = splay(nodes, left, key);
                    nodes[joined].right = right;
                    root = joined;
                }
            }
        }
    }
    int64_t final_keys[MAX_KEYS];
    size_t final_count = 0;
    inorder(nodes, root, final_keys, &final_count);
    uint8_t staged[MAX_OUTPUT];
    size_t written = 0;
    write_word(staged, &written, (int64_t)op_count);
    for (size_t i = 0; i < op_count; ++i) write_word(staged, &written, result_tags[i]);
    write_word(staged, &written, (int64_t)final_count);
    for (size_t i = 0; i < final_count; ++i) write_word(staged, &written, final_keys[i]);
    if (output == NULL || capacity < written) return -2;
    for (size_t i = 0; i < written; ++i) output[i] = staged[i];
    return (int64_t)written;
}
