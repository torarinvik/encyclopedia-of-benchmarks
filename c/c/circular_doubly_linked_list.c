/* Bounded circular doubly linked-list operation trace with a sentinel ring. */
#include <stddef.h>
#include <stdint.h>

#define CAPACITY 256
#define SENTINEL ((size_t)CAPACITY)
#define VALUE_OFFSET INT64_C(1000000)
#define MAX_INDEX INT64_C(1000000)

int64_t circular_doubly_linked_list_benchmark(const int64_t *values, size_t length)
{
    if (length > 1024 || length % 2 != 0) return -1;
    const size_t operation_count = length / 2;
    int64_t node_value[CAPACITY];
    size_t next_node[CAPACITY + 1], prev_node[CAPACITY + 1];
    for (size_t i = 0; i < CAPACITY; ++i) next_node[i] = i + 1;
    size_t free_head = 0;
    next_node[SENTINEL] = SENTINEL;
    prev_node[SENTINEL] = SENTINEL;
    size_t count = 0;
    int64_t checksum = 0;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = values[2 * operation];
        const int64_t payload = values[2 * operation + 1];
        int64_t observed = 0;
        int returns_value = 1;
        if (opcode == 0 || opcode == 1) {
            if (payload < -VALUE_OFFSET || payload > VALUE_OFFSET || count == CAPACITY || free_head == SENTINEL) return -1;
            const size_t node = free_head;
            free_head = next_node[node];
            node_value[node] = payload;
            const size_t before = opcode == 0 ? prev_node[SENTINEL] : SENTINEL;
            const size_t after = opcode == 0 ? SENTINEL : next_node[SENTINEL];
            next_node[node] = after;
            prev_node[node] = before;
            next_node[before] = node;
            prev_node[after] = node;
            ++count;
            returns_value = 0;
        } else if (opcode == 2 || opcode == 3) {
            if (payload != 0 || count == 0) return -1;
            const size_t node = opcode == 2 ? next_node[SENTINEL] : prev_node[SENTINEL];
            observed = node_value[node];
            next_node[prev_node[node]] = next_node[node];
            prev_node[next_node[node]] = prev_node[node];
            next_node[node] = free_head;
            free_head = node;
            --count;
        } else if (opcode == 4 || opcode == 5) {
            if (payload < -VALUE_OFFSET || payload > VALUE_OFFSET) return -1;
            size_t node = next_node[SENTINEL];
            while (node != SENTINEL && node_value[node] != payload) node = next_node[node];
            observed = node != SENTINEL;
            if (opcode == 4 && node != SENTINEL) {
                next_node[prev_node[node]] = next_node[node];
                prev_node[next_node[node]] = prev_node[node];
                next_node[node] = free_head;
                free_head = node;
                --count;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = (int64_t)count;
        } else if (opcode == 7 || opcode == 8) {
            if (payload < 0 || payload > MAX_INDEX || count == 0) return -1;
            if (opcode == 8 && (uint64_t)payload >= count) return -1;
            size_t index = opcode == 7 ? (size_t)(payload % (int64_t)count) : (size_t)payload;
            size_t node;
            if (index <= count / 2) {
                node = next_node[SENTINEL];
                for (size_t i = 0; i < index; ++i) node = next_node[node];
            } else {
                node = prev_node[SENTINEL];
                for (size_t i = count - 1; i > index; --i) node = prev_node[node];
            }
            observed = node_value[node];
            if (opcode == 8) {
                next_node[prev_node[node]] = next_node[node];
                prev_node[next_node[node]] = prev_node[node];
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
    node = prev_node[SENTINEL];
    index = 0;
    while (node != SENTINEL) {
        checksum += ((int64_t)operation_count + (int64_t)count + (int64_t)index + 1) * (node_value[node] + VALUE_OFFSET);
        node = prev_node[node];
        ++index;
    }
    return checksum;
}
