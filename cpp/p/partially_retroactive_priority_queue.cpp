#include <stddef.h>
#include <stdint.h>

#define MAX_N 64u
#define MAX_Q 64u
#define MAX_INPUT 323u
#define MAX_OUTPUT (16u * MAX_Q)
#define TREE_BASE 128u
#define TREE_SIZE (2u * TREE_BASE)

typedef struct {
    int32_t balance;
    int32_t prefix_min;
    int32_t suffix_max;
    int32_t min_insert;
    int32_t max_delete;
} Segment;

typedef struct {
    size_t n;
    size_t base;
    int32_t type[MAX_N + 1u];
    int64_t value[MAX_N + 1u];
    Segment tree[TREE_SIZE];
    int64_t live_sum;
    int64_t live_count;
} RetroQueue;

static int32_t pick_min_insert(const RetroQueue *q, int32_t a, int32_t b) {
    if (a == 0) return b;
    if (b == 0) return a;
    if (q->value[a] != q->value[b]) return q->value[a] < q->value[b] ? a : b;
    return a > b ? a : b;
}

static int32_t pick_max_delete(const RetroQueue *q, int32_t a, int32_t b) {
    if (a == -1) return b;
    if (b == -1) return a;
    if (a == 0 || b == 0) return 0;
    if (q->value[a] != q->value[b]) return q->value[a] > q->value[b] ? a : b;
    return a < b ? a : b;
}

static void pull_path(RetroQueue *q, size_t i) {
    size_t p = (q->base + i) >> 1;
    while (p != 0u) {
        Segment *node = &q->tree[p];
        const Segment *left = &q->tree[p << 1];
        const Segment *right = &q->tree[(p << 1) | 1u];
        node->balance = left->balance + right->balance;
        const int32_t across_min = left->balance + right->prefix_min;
        node->prefix_min = left->prefix_min < across_min ? left->prefix_min : across_min;
        const int32_t across_max = left->suffix_max + right->balance;
        node->suffix_max = across_max > right->suffix_max ? across_max : right->suffix_max;
        node->min_insert = pick_min_insert(q, left->min_insert, right->min_insert);
        node->max_delete = pick_max_delete(q, left->max_delete, right->max_delete);
        p >>= 1;
    }
}

static size_t next_bridge(const RetroQueue *q, size_t i) {
    size_t left = q->base;
    size_t right = q->base + i + 1u;
    int32_t acc = 0;
    while (left < right) {
        if (left & 1u) acc += q->tree[left++].balance;
        if (right & 1u) acc += q->tree[--right].balance;
        left >>= 1;
        right >>= 1;
    }
    if (acc == 0) return i + 1u;
    size_t node = q->base + i + 1u;
    for (;;) {
        while ((node & 1u) == 0u) node >>= 1;
        if (acc + q->tree[node].prefix_min == 0) {
            while (node < q->base) {
                node <<= 1;
                if (acc + q->tree[node].prefix_min > 0) {
                    acc += q->tree[node].balance;
                    ++node;
                }
            }
            return node - q->base;
        }
        acc += q->tree[node].balance;
        ++node;
        if ((node & (~node + 1u)) == node) return q->base;
    }
}

static size_t prev_bridge(const RetroQueue *q, size_t i) {
    size_t left = q->base + i;
    size_t right = q->base * 2u;
    int32_t acc = 0;
    while (left < right) {
        if (left & 1u) acc += q->tree[left++].balance;
        if (right & 1u) acc += q->tree[--right].balance;
        left >>= 1;
        right >>= 1;
    }
    if (acc == 0) return i;
    size_t node = q->base + i;
    for (;;) {
        --node;
        while (node > 1u && (node & 1u) != 0u) node >>= 1;
        if (q->tree[node].suffix_max + acc == 0) {
            while (node < q->base) {
                node = (node << 1) | 1u;
                if (q->tree[node].suffix_max + acc < 0) {
                    acc += q->tree[node].balance;
                    --node;
                }
            }
            return node - q->base;
        }
        acc += q->tree[node].balance;
        if ((node & (~node + 1u)) == node) return 0u;
    }
}

static int32_t range_min_insert(const RetroQueue *q, size_t end) {
    size_t left = q->base;
    size_t right = q->base + end;
    int32_t answer = 0;
    while (left < right) {
        if (left & 1u) answer = pick_min_insert(q, answer, q->tree[left++].min_insert);
        if (right & 1u) answer = pick_min_insert(q, answer, q->tree[--right].min_insert);
        left >>= 1;
        right >>= 1;
    }
    return answer;
}

static int32_t range_max_delete(const RetroQueue *q, size_t begin) {
    size_t left = q->base + begin;
    size_t right = q->base * 2u;
    int32_t answer = -1;
    while (left < right) {
        if (left & 1u) answer = pick_max_delete(q, answer, q->tree[left++].max_delete);
        if (right & 1u) answer = pick_max_delete(q, answer, q->tree[--right].max_delete);
        left >>= 1;
        right >>= 1;
    }
    return answer;
}

static int32_t find_min_insert(const RetroQueue *q, size_t i) {
    return range_min_insert(q, next_bridge(q, i));
}

static int32_t find_max_delete(const RetroQueue *q, size_t i) {
    return range_max_delete(q, prev_bridge(q, i));
}

static void add_operation(RetroQueue *q, size_t i) {
    const int32_t k = find_max_delete(q, i);
    Segment *leaf = &q->tree[q->base + i];
    if (pick_max_delete(q, (int32_t)i, k) == (int32_t)i) {
        q->live_sum += q->value[i];
        ++q->live_count;
        leaf->min_insert = (int32_t)i;
        pull_path(q, i);
        return;
    }
    leaf->max_delete = (int32_t)i;
    leaf->balance = 1;
    leaf->suffix_max = 1;
    pull_path(q, i);
    Segment *mate = &q->tree[q->base + (size_t)k];
    if (k == 0) {
        --mate->balance;
        --mate->suffix_max;
        if (mate->balance == 0) mate->max_delete = -1;
    } else {
        q->live_sum += q->value[k];
        ++q->live_count;
        mate->min_insert = k;
        mate->max_delete = -1;
        mate->balance = 0;
        mate->suffix_max = 0;
    }
    pull_path(q, (size_t)k);
}

static void remove_insert(RetroQueue *q, size_t i) {
    Segment *leaf = &q->tree[q->base + i];
    if (leaf->balance == 0) {
        q->live_sum -= q->value[i];
        --q->live_count;
        leaf->min_insert = 0;
        pull_path(q, i);
        return;
    }
    const int32_t k = find_min_insert(q, i);
    leaf->max_delete = -1;
    leaf->balance = 0;
    leaf->suffix_max = 0;
    pull_path(q, i);
    Segment *mate = &q->tree[q->base + (size_t)k];
    if (k > 0) {
        q->live_sum -= q->value[k];
        --q->live_count;
    }
    mate->min_insert = 0;
    mate->max_delete = k;
    ++mate->balance;
    ++mate->suffix_max;
    pull_path(q, (size_t)k);
}

static void remove_minimum(RetroQueue *q, size_t i) {
    const int32_t k = find_min_insert(q, i);
    Segment *leaf = &q->tree[q->base + i];
    leaf->balance = -1;
    leaf->prefix_min = -1;
    pull_path(q, i);
    if (k > 0) {
        q->live_sum -= q->value[k];
        --q->live_count;
    }
    Segment *mate = &q->tree[q->base + (size_t)k];
    mate->min_insert = 0;
    mate->max_delete = k;
    ++mate->balance;
    ++mate->suffix_max;
    pull_path(q, (size_t)k);
}

static void restore_minimum(RetroQueue *q, size_t i) {
    const int32_t k = find_max_delete(q, i);
    Segment *leaf = &q->tree[q->base + i];
    Segment *mate = &q->tree[q->base + (size_t)k];
    leaf->balance = 0;
    leaf->prefix_min = 0;
    pull_path(q, i);
    if (k == 0) {
        --mate->balance;
        --mate->suffix_max;
        if (mate->balance == 0) mate->max_delete = -1;
    } else {
        q->live_sum += q->value[k];
        ++q->live_count;
        mate->min_insert = k;
        mate->max_delete = -1;
        mate->balance = 0;
        mate->suffix_max = 0;
    }
    pull_path(q, (size_t)k);
}

static void set_operation(RetroQueue *q, size_t zero_based_i, int32_t type, int64_t value) {
    const size_t i = zero_based_i + 1u;
    if (q->type[i] == 0) remove_insert(q, i);
    else if (q->type[i] == 1) restore_minimum(q, i);
    q->type[i] = type;
    q->value[i] = value;
    if (type == 0) add_operation(q, i);
    else if (type == 1) remove_minimum(q, i);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8u; ++byte) {
        output[offset + byte] = (uint8_t)(bits >> (8u * byte));
    }
}

extern "C" int64_t partially_retroactive_priority_queue(const int64_t *input, size_t input_length,
                                                          uint8_t *output, size_t capacity) {
    if (input == NULL || input_length < 2u || input_length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (int64_t)MAX_N || input[1] < 1 || input[1] > (int64_t)MAX_Q) return -1;
    const size_t n = (size_t)input[0];
    const size_t qn = (size_t)input[1];
    if (input_length != 2u + 2u * n + 3u * qn) return -1;
    size_t at = 2u;
    for (size_t i = 0; i < n; ++i) {
        const int64_t type = input[at++];
        const int64_t value = input[at++];
        if (type == 0) {
            if (value < 0 || value > 1000000) return -1;
        } else if ((type == 1 || type == 2) && value == -1) {
        } else return -1;
    }
    for (size_t i = 0; i < qn; ++i) {
        const int64_t index = input[at++];
        const int64_t type = input[at++];
        const int64_t value = input[at++];
        if (index < 0 || index >= (int64_t)n) return -1;
        if (type == 0) {
            if (value < 0 || value > 1000000) return -1;
        } else if ((type == 1 || type == 2) && value == -1) {
        } else return -1;
    }
    const size_t output_size = 16u * qn;
    if (output == NULL || capacity < output_size) return -2;

    RetroQueue queue = {0};
    queue.n = n;
    queue.base = TREE_BASE;
    for (size_t i = 0; i <= n; ++i) {
        queue.type[i] = 2;
        queue.value[i] = -1;
    }
    for (size_t i = 0; i < TREE_SIZE; ++i) queue.tree[i].max_delete = -1;
    at = 2u;
    for (size_t i = 0; i < n; ++i) {
        const int32_t type = (int32_t)input[at++];
        const int64_t value = input[at++];
        set_operation(&queue, i, type, value);
    }
    size_t written = 0;
    for (size_t i = 0; i < qn; ++i) {
        const size_t index = (size_t)input[at++];
        const int32_t type = (int32_t)input[at++];
        const int64_t value = input[at++];
        set_operation(&queue, index, type, value);
        store_i64_le(output, written, queue.live_count);
        store_i64_le(output, written + 8u, queue.live_sum);
        written += 16u;
    }
    return (int64_t)written;
}
