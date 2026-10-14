/* Bounded doubly linked list with a portable index-based node pool. */
#include <stddef.h>
#include <stdint.h>

#define CAPACITY 256
#define NONE ((size_t)CAPACITY)
#define VALUE_OFFSET INT64_C(1000000)

int64_t doubly_linked_list_benchmark(const int64_t *values, size_t length)
{
    if (length > 1024 || length % 2 != 0) return -1;
    const size_t operation_count = length / 2;
    int64_t node_value[CAPACITY];
    size_t next_node[CAPACITY], prev_node[CAPACITY];
    for (size_t i = 0; i < CAPACITY; ++i) next_node[i] = i + 1;
    size_t free_head = 0, head = NONE, tail = NONE, count = 0;
    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = values[2 * operation], payload = values[2 * operation + 1];
        int64_t observed = 0;
        int returns_value = 1;
        if (opcode == 0 || opcode == 1) {
            if (payload < -VALUE_OFFSET || payload > VALUE_OFFSET || count == CAPACITY || free_head == NONE) return -1;
            const size_t node = free_head;
            free_head = next_node[node];
            node_value[node] = payload;
            next_node[node] = NONE;
            prev_node[node] = NONE;
            if (opcode == 0) {
                if (tail == NONE) head = node;
                else { prev_node[node] = tail; next_node[tail] = node; }
                tail = node;
            } else {
                if (head == NONE) tail = node;
                else { next_node[node] = head; prev_node[head] = node; }
                head = node;
            }
            ++count;
            returns_value = 0;
        } else if (opcode == 2 || opcode == 3) {
            if (payload != 0 || count == 0) return -1;
            const size_t node = opcode == 2 ? head : tail;
            observed = node_value[node];
            const size_t before = prev_node[node], after = next_node[node];
            if (before == NONE) head = after; else next_node[before] = after;
            if (after == NONE) tail = before; else prev_node[after] = before;
            next_node[node] = free_head; free_head = node; --count;
        } else if (opcode == 4 || opcode == 5) {
            if (payload < -VALUE_OFFSET || payload > VALUE_OFFSET) return -1;
            size_t node = head;
            while (node != NONE && node_value[node] != payload) node = next_node[node];
            observed = (node != NONE);
            if (opcode == 4 && node != NONE) {
                const size_t before = prev_node[node], after = next_node[node];
                if (before == NONE) head = after; else next_node[before] = after;
                if (after == NONE) tail = before; else prev_node[after] = before;
                next_node[node] = free_head; free_head = node; --count;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = (int64_t)count;
        } else return -1;
        if (returns_value) checksum += ((int64_t)operation + 1) * (observed + VALUE_OFFSET);
    }
    size_t node = head, index = 0;
    while (node != NONE) {
        checksum += ((int64_t)operation_count + (int64_t)index + 1) * (node_value[node] + VALUE_OFFSET);
        node = next_node[node]; ++index;
    }
    node = tail; index = 0;
    while (node != NONE) {
        checksum += ((int64_t)operation_count + (int64_t)count + (int64_t)index + 1) * (node_value[node] + VALUE_OFFSET);
        node = prev_node[node]; ++index;
    }
    return checksum;
}
