#include <cstddef>
#include <cstdint>

namespace {
constexpr int32_t LIST_SIZE = 100;
constexpr int64_t MIN_RUNS = 0;
constexpr int64_t MAX_RUNS = 10000;
constexpr int NODE_COUNT = 203;

struct ListNode { int32_t value; int32_t next; int32_t prev; };

void initSequence(ListNode *nodes, int32_t head, int32_t base) {
    nodes[head].value = LIST_SIZE;
    nodes[head].next = base;
    nodes[head].prev = base + LIST_SIZE - 1;
    for (int32_t offset = 0; offset < LIST_SIZE; ++offset) {
        const int32_t item = base + offset;
        nodes[item].value = offset + 1;
        nodes[item].prev = offset == 0 ? head : item - 1;
        nodes[item].next = offset + 1 == LIST_SIZE ? head : item + 1;
    }
}

int32_t listLength(const ListNode *nodes, int32_t head) { return nodes[head].value; }

int32_t popHead(ListNode *nodes, int32_t head) {
    if (listLength(nodes, head) == 0) return -1;
    const int32_t item = nodes[head].next;
    const int32_t next = nodes[item].next;
    nodes[head].next = next;
    nodes[next].prev = head;
    --nodes[head].value;
    return item;
}

int32_t popTail(ListNode *nodes, int32_t head) {
    if (listLength(nodes, head) == 0) return -1;
    const int32_t item = nodes[head].prev;
    const int32_t prev = nodes[item].prev;
    nodes[head].prev = prev;
    nodes[prev].next = head;
    --nodes[head].value;
    return item;
}

void pushTail(ListNode *nodes, int32_t head, int32_t item) {
    const int32_t tail = nodes[head].prev;
    nodes[tail].next = item;
    nodes[item].next = head;
    nodes[head].prev = item;
    nodes[item].prev = tail;
    ++nodes[head].value;
}

void reverseList(ListNode *nodes, int32_t head) {
    int32_t current = head;
    do {
        const int32_t oldNext = nodes[current].next;
        nodes[current].next = nodes[current].prev;
        nodes[current].prev = oldNext;
        current = oldNext;
    } while (current != head);
}

bool listsEqual(const ListNode *nodes, int32_t left, int32_t right) {
    if (listLength(nodes, left) != listLength(nodes, right)) return false;
    int32_t a = nodes[left].next;
    int32_t b = nodes[right].next;
    while (a != left && b != right) {
        if (nodes[a].value != nodes[b].value) return false;
        a = nodes[a].next;
        b = nodes[b].next;
    }
    return a == left && b == right;
}

int32_t testLists() {
    ListNode nodes[NODE_COUNT]{};
    constexpr int32_t original = 0, copied = 101, staging = 202;
    initSequence(nodes, original, 1);
    initSequence(nodes, copied, 102);
    nodes[staging].value = 0;
    nodes[staging].next = staging;
    nodes[staging].prev = staging;
    if (!listsEqual(nodes, copied, original)) return -1;
    while (listLength(nodes, copied) > 0) {
        const int32_t item = popHead(nodes, copied);
        if (item < 0) return -1;
        pushTail(nodes, staging, item);
    }
    if (listLength(nodes, copied) != 0) return -1;
    while (listLength(nodes, staging) > 0) {
        const int32_t item = popTail(nodes, staging);
        if (item < 0) return -1;
        pushTail(nodes, copied, item);
    }
    if (listLength(nodes, staging) != 0) return -1;
    reverseList(nodes, original);
    if (nodes[nodes[original].next].value != LIST_SIZE) return -1;
    if (nodes[nodes[original].prev].value != 1) return -1;
    if (nodes[nodes[copied].next].value != LIST_SIZE) return -1;
    if (nodes[nodes[copied].prev].value != 1) return -1;
    if (listLength(nodes, original) != LIST_SIZE) return -1;
    if (!listsEqual(nodes, original, copied)) return -1;
    return listLength(nodes, original);
}
} // namespace

extern "C" int64_t shootout_lists(int64_t runs, uint8_t *output, size_t output_capacity) {
    if (runs < MIN_RUNS || runs > MAX_RUNS) return -1;
    if (output == nullptr) return -2;
    const uint8_t zeroOutput[2] = {'0', '\n'};
    const uint8_t positiveOutput[4] = {'1', '0', '0', '\n'};
    const uint8_t *staged = runs == 0 ? zeroOutput : positiveOutput;
    const size_t outputBytes = runs == 0 ? 2 : 4;
    if (output_capacity < outputBytes) return -2;
    int32_t result = 0;
    for (int64_t run = 0; run < runs; ++run) {
        result = testLists();
        if (result != LIST_SIZE) return -1;
    }
    for (size_t index = 0; index < outputBytes; ++index) output[index] = staged[index];
    return static_cast<int64_t>(outputBytes);
}
