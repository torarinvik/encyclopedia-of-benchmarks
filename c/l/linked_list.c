/* Bounded singly linked list with a portable index-based node pool. */
#include <stddef.h>
#include <stdint.h>

#define CAPACITY 256
#define NONE ((size_t)CAPACITY)
#define VALUE_OFFSET INT64_C(1000000)

int64_t linked_list_benchmark(const int64_t *values, size_t length)
{
    if (length > 1024 || length % 2 != 0) return -1;
    const size_t operation_count = length / 2;
    int64_t node_value[CAPACITY];
    size_t next_node[CAPACITY];
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
            if (opcode == 0) {
                if (tail == NONE) head = node;
                else next_node[tail] = node;
                tail = node;
                next_node[node] = NONE;
            } else {
                next_node[node] = head;
                head = node;
                if (tail == NONE) tail = node;
            }
            ++count;
            returns_value = 0;
        } else if (opcode == 2) {
            if (payload != 0 || count == 0) return -1;
            const size_t node = head;
            observed = node_value[node];
            head = next_node[node];
            if (head == NONE) tail = NONE;
            next_node[node] = free_head;
            free_head = node;
            --count;
        } else if (opcode == 3) {
            if (payload != 0 || count == 0) return -1;
            const size_t node = tail;
            observed = node_value[node];
            if (head == tail) head = tail = NONE;
            else {
                size_t before = head;
                while (next_node[before] != tail) before = next_node[before];
                tail = before;
                next_node[before] = NONE;
            }
            next_node[node] = free_head;
            free_head = node;
            --count;
        } else if (opcode == 4 || opcode == 5) {
            if (payload < -VALUE_OFFSET || payload > VALUE_OFFSET) return -1;
            size_t before = NONE, node = head;
            while (node != NONE && node_value[node] != payload) {
                before = node;
                node = next_node[node];
            }
            observed = (node != NONE);
            if (opcode == 4 && node != NONE) {
                if (before == NONE) head = next_node[node];
                else next_node[before] = next_node[node];
                if (tail == node) tail = before;
                next_node[node] = free_head;
                free_head = node;
                --count;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = (int64_t)count;
        } else if (opcode == 7) {
            if (payload != 0) return -1;
            size_t previous = NONE, node = head;
            tail = head;
            while (node != NONE) {
                const size_t next = next_node[node];
                next_node[node] = previous;
                previous = node;
                node = next;
            }
            head = previous;
            returns_value = 0;
        } else return -1;
        if (returns_value) checksum += ((int64_t)operation + 1) * (observed + VALUE_OFFSET);
    }
    size_t node = head, index = 0;
    while (node != NONE) {
        checksum += ((int64_t)operation_count + (int64_t)index + 1) * (node_value[node] + VALUE_OFFSET);
        node = next_node[node];
        ++index;
    }
    return checksum;
}
