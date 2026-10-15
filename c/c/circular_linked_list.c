/* Bounded singly circular linked-list operation trace with a sentinel ring. */
#include <stddef.h>
#include <stdint.h>

#define CAPACITY 256
#define SENTINEL ((size_t)CAPACITY)
#define VALUE_OFFSET INT64_C(1000000)
#define MAX_INDEX INT64_C(1000000)

int64_t circular_linked_list_benchmark(const int64_t *values, size_t length)
{
    if (length > 1024 || length % 2 != 0) return -1;
    const size_t operation_count = length / 2;
    int64_t node_value[CAPACITY];
    size_t next_node[CAPACITY + 1];
    for (size_t i = 0; i < CAPACITY; ++i) next_node[i] = i + 1;
    next_node[SENTINEL] = SENTINEL;
    size_t free_head = 0, tail = SENTINEL, count = 0;
    int64_t checksum = 0;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = values[2 * operation], payload = values[2 * operation + 1];
        int64_t observed = 0;
        int returns_value = 1;
        if (opcode == 0 || opcode == 1) {
            if (payload < -VALUE_OFFSET || payload > VALUE_OFFSET || count == CAPACITY || free_head == SENTINEL) return -1;
            const size_t node = free_head;
            free_head = next_node[node];
            node_value[node] = payload;
            if (opcode == 0) {
                next_node[node] = SENTINEL;
                next_node[tail] = node;
                tail = node;
            } else {
                next_node[node] = next_node[SENTINEL];
                next_node[SENTINEL] = node;
                if (count == 0) tail = node;
            }
            ++count;
            returns_value = 0;
        } else if (opcode == 2 || opcode == 3) {
            if (payload != 0 || count == 0) return -1;
            size_t previous = SENTINEL;
            if (opcode == 3) {
                while (next_node[previous] != tail) previous = next_node[previous];
            }
            const size_t node = next_node[previous];
            observed = node_value[node];
            next_node[previous] = next_node[node];
            if (node == tail) tail = previous;
            next_node[node] = free_head;
            free_head = node;
            --count;
        } else if (opcode == 4 || opcode == 5) {
            if (payload < -VALUE_OFFSET || payload > VALUE_OFFSET) return -1;
            size_t previous = SENTINEL;
            while (next_node[previous] != SENTINEL && node_value[next_node[previous]] != payload)
                previous = next_node[previous];
            const size_t node = next_node[previous];
            observed = node != SENTINEL;
            if (opcode == 4 && node != SENTINEL) {
                next_node[previous] = next_node[node];
                if (node == tail) tail = previous;
                next_node[node] = free_head;
                free_head = node;
                --count;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = (int64_t)count;
        } else if (opcode == 7 || opcode == 8) {
            if (payload < 0 || payload > MAX_INDEX || count == 0 || (uint64_t)payload >= count) return -1;
            size_t previous = SENTINEL;
            for (size_t index = 0; index < (size_t)payload; ++index) previous = next_node[previous];
            const size_t node = next_node[previous];
            observed = node_value[node];
            if (opcode == 8) {
                next_node[previous] = next_node[node];
                if (node == tail) tail = previous;
                next_node[node] = free_head;
                free_head = node;
                --count;
            }
        } else return -1;
        if (returns_value) checksum += ((int64_t)operation + 1) * (observed + VALUE_OFFSET);
    }

    size_t node = next_node[SENTINEL], index = 0;
    while (node != SENTINEL) {
        checksum += ((int64_t)operation_count + (int64_t)index + 1) * (node_value[node] + VALUE_OFFSET);
        node = next_node[node];
        ++index;
    }
    return checksum;
}
