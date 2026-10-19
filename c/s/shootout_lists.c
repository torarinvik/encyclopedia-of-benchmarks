#include <stddef.h>
#include <stdint.h>

#define LIST_SIZE 100
#define MIN_RUNS INT64_C(0)
#define MAX_RUNS INT64_C(10000)
#define NODE_COUNT 203

typedef struct ListNode {
    int32_t value;
    int32_t next;
    int32_t prev;
} ListNode;

static void init_sequence(ListNode *nodes, int32_t head, int32_t base) {
    nodes[head].value = LIST_SIZE;
    nodes[head].next = base;
    nodes[head].prev = base + LIST_SIZE - 1;
    for (int32_t offset = 0; offset < LIST_SIZE; ++offset) {
        int32_t item = base + offset;
        nodes[item].value = offset + 1;
        nodes[item].prev = offset == 0 ? head : item - 1;
        nodes[item].next = offset + 1 == LIST_SIZE ? head : item + 1;
    }
}

static int32_t list_length(const ListNode *nodes, int32_t head) {
    return nodes[head].value;
}

static int32_t pop_head(ListNode *nodes, int32_t head) {
    if (list_length(nodes, head) == 0) return -1;
    int32_t item = nodes[head].next;
    int32_t next = nodes[item].next;
    nodes[head].next = next;
    nodes[next].prev = head;
    --nodes[head].value;
    return item;
}

static int32_t pop_tail(ListNode *nodes, int32_t head) {
    if (list_length(nodes, head) == 0) return -1;
    int32_t item = nodes[head].prev;
    int32_t prev = nodes[item].prev;
    nodes[head].prev = prev;
    nodes[prev].next = head;
    --nodes[head].value;
    return item;
}

static void push_tail(ListNode *nodes, int32_t head, int32_t item) {
    int32_t tail = nodes[head].prev;
    nodes[tail].next = item;
    nodes[item].next = head;
    nodes[head].prev = item;
    nodes[item].prev = tail;
    ++nodes[head].value;
}

static void reverse_list(ListNode *nodes, int32_t head) {
    int32_t current = head;
    do {
        int32_t old_next = nodes[current].next;
        nodes[current].next = nodes[current].prev;
        nodes[current].prev = old_next;
        current = old_next;
    } while (current != head);
}

static int lists_equal(const ListNode *nodes, int32_t left, int32_t right) {
    if (list_length(nodes, left) != list_length(nodes, right)) return 0;
    int32_t a = nodes[left].next;
    int32_t b = nodes[right].next;
    while (a != left && b != right) {
        if (nodes[a].value != nodes[b].value) return 0;
        a = nodes[a].next;
        b = nodes[b].next;
    }
    return a == left && b == right;
}

static int32_t test_lists(void) {
    ListNode nodes[NODE_COUNT] = {0};
    const int32_t original = 0;
    const int32_t copied = 101;
    const int32_t staging = 202;
    init_sequence(nodes, original, 1);
    init_sequence(nodes, copied, 102);
    nodes[staging].value = 0;
    nodes[staging].next = staging;
    nodes[staging].prev = staging;
    if (!lists_equal(nodes, copied, original)) return -1;
    while (list_length(nodes, copied) > 0) {
        int32_t item = pop_head(nodes, copied);
        if (item < 0) return -1;
        push_tail(nodes, staging, item);
    }
    if (list_length(nodes, copied) != 0) return -1;
    while (list_length(nodes, staging) > 0) {
        int32_t item = pop_tail(nodes, staging);
        if (item < 0) return -1;
        push_tail(nodes, copied, item);
    }
    if (list_length(nodes, staging) != 0) return -1;
    reverse_list(nodes, original);
    if (nodes[nodes[original].next].value != LIST_SIZE) return -1;
    if (nodes[nodes[original].prev].value != 1) return -1;
    if (nodes[nodes[copied].next].value != LIST_SIZE) return -1;
    if (nodes[nodes[copied].prev].value != 1) return -1;
    if (list_length(nodes, original) != LIST_SIZE) return -1;
    if (!lists_equal(nodes, original, copied)) return -1;
    return list_length(nodes, original);
}

int64_t shootout_lists(int64_t runs, uint8_t *output, size_t output_capacity) {
    if (runs < MIN_RUNS || runs > MAX_RUNS) return -1;
    if (output == NULL) return -2;
    const uint8_t zero_output[2] = {'0', '\n'};
    const uint8_t positive_output[4] = {'1', '0', '0', '\n'};
    const uint8_t *staged = runs == 0 ? zero_output : positive_output;
    const size_t output_bytes = runs == 0 ? 2 : 4;
    if (output_capacity < output_bytes) return -2;
    int32_t result = 0;
    for (int64_t run = 0; run < runs; ++run) {
        result = test_lists();
        if (result != LIST_SIZE) return -1;
    }
    for (size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return (int64_t)output_bytes;
}
