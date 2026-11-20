#include <stddef.h>
#include <stdint.h>

#define MAX_OPS 48
#define HANDLES 8
#define MAX_WORDS (1 + 3 * MAX_OPS)
#define PARSEABLE_WORDS (MAX_WORDS + 1)

typedef struct {
    int64_t value;
    int32_t next;
    int32_t child;
    uint8_t kind;
    uint8_t live;
} Node;

static int32_t normalize(int32_t head, const Node nodes[MAX_OPS]) {
    while (head >= 0 && nodes[head].kind == 1 && !nodes[head].live) {
        head = nodes[head].next;
    }
    return head;
}

static int top_value(int32_t head, const Node nodes[MAX_OPS], int64_t *value) {
    head = normalize(head, nodes);
    while (head >= 0 && nodes[head].kind == 1) {
        head = normalize(nodes[head].next, nodes);
    }
    if (head < 0) return 0;
    *value = nodes[head].value;
    return 1;
}

static void store_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[offset + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

int64_t cactus_stack_branch_trace(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > PARSEABLE_WORDS) return -1;
    int64_t q_value = input[0];
    if (q_value < 0 || q_value > MAX_OPS || length != 1 + 3 * (size_t)q_value) return -1;
    size_t q = (size_t)q_value;
    for (size_t i = 0; i < q; ++i) {
        int64_t op = input[1 + 3 * i];
        int64_t a = input[2 + 3 * i];
        int64_t b = input[3 + 3 * i];
        if (op == 0) {
            if (a < 0 || a >= HANDLES || b < -1000 || b > 1000) return -1;
        } else if (op >= 1 && op <= 3) {
            if (a < 0 || a >= HANDLES || b != 0) return -1;
        } else if (op == 4) {
            if (a < 0 || a >= HANDLES || b < 0 || b >= HANDLES) return -1;
        } else return -1;
    }

    Node nodes[MAX_OPS];
    int32_t heads[HANDLES], branch_child[HANDLES], attached_owner[HANDLES];
    int32_t wrapper_for_child[HANDLES];
    int64_t statuses[MAX_OPS], results[MAX_OPS];
    for (size_t h = 0; h < HANDLES; ++h) {
        heads[h] = -1;
        branch_child[h] = -1;
        attached_owner[h] = -1;
        wrapper_for_child[h] = -1;
    }
    size_t node_count = 0;
    for (size_t i = 0; i < q; ++i) {
        int32_t op = (int32_t)input[1 + 3 * i];
        int32_t a = (int32_t)input[2 + 3 * i];
        int64_t b = input[3 + 3 * i];
        heads[a] = normalize(heads[a], nodes);
        int32_t head = heads[a];
        statuses[i] = 1;
        results[i] = 0;
        if (op == 0) {
            Node node = {b, head, -1, 0, 0};
            nodes[node_count] = node;
            heads[a] = (int32_t)node_count++;
        } else if (op == 1) {
            if (head < 0 || (nodes[head].kind == 1 && nodes[head].live)) {
                statuses[i] = 0;
            } else {
                results[i] = nodes[head].value;
                heads[a] = normalize(nodes[head].next, nodes);
                if (heads[a] < 0 && attached_owner[a] >= 0) {
                    int32_t owner = attached_owner[a];
                    nodes[wrapper_for_child[a]].live = 0;
                    branch_child[owner] = -1;
                    attached_owner[a] = -1;
                    wrapper_for_child[a] = -1;
                }
            }
        } else if (op == 2) {
            int64_t value = 0;
            if (top_value(head, nodes, &value)) results[i] = value;
            else statuses[i] = 0;
        } else if (op == 3) {
            results[i] = head >= 0 && nodes[head].kind == 1 && nodes[head].live ? 1 : 0;
        } else {
            int32_t child = (int32_t)b;
            heads[child] = normalize(heads[child], nodes);
            int64_t ignored = 0;
            int owner_nonempty = top_value(head, nodes, &ignored);
            if (a == child || !owner_nonempty || attached_owner[a] >= 0
                || branch_child[a] >= 0 || attached_owner[child] >= 0
                || branch_child[child] >= 0) return -1;
            if (heads[child] < 0) {
                results[i] = 0;
            } else {
                Node node = {0, head, child, 1, 1};
                nodes[node_count] = node;
                int32_t wrapper = (int32_t)node_count++;
                heads[a] = wrapper;
                branch_child[a] = child;
                attached_owner[child] = a;
                wrapper_for_child[child] = wrapper;
                results[i] = 1;
            }
        }
    }

    size_t required = 16 * q;
    if (output == NULL || capacity < required) return -2;
    for (size_t i = 0; i < q; ++i) {
        store_i64(output, 16 * i, statuses[i]);
        store_i64(output, 16 * i + 8, results[i]);
    }
    return (int64_t)required;
}
