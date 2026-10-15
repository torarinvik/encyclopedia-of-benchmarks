/* Bounded linked-node pool for an ascending priority queue. */
#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 512
#define MAX_CAPACITY 64

typedef struct {
    int64_t value;
    int next;
} Node;

int64_t ascending_priority_queue(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > MAX_OPERATIONS
        || length != 1 + 2 * (size_t)input[0]) return -1;

    Node nodes[MAX_CAPACITY];
    for (int index = 0; index < MAX_CAPACITY - 1; ++index) nodes[index].next = index + 1;
    nodes[MAX_CAPACITY - 1].next = -1;
    int free_head = 0, front = -1, rear = -1;
    int64_t checksum = 0;

    for (size_t operation = 0; operation < (size_t)input[0]; ++operation) {
        const int64_t opcode = input[1 + 2 * operation];
        const int64_t payload = input[2 + 2 * operation];
        if (opcode == 0) {
            if (payload < -1000000 || payload > 1000000 || free_head < 0) return -1;
            const int node = free_head;
            free_head = nodes[node].next;
            nodes[node].value = payload;
            nodes[node].next = -1;
            if (front < 0) front = rear = node;
            else { nodes[rear].next = node; rear = node; }
        } else if (opcode == 1) {
            if (payload != 0 || front < 0) return -1;
            int previous = -1, current = front;
            int minimum = front, minimum_previous = -1;
            while (current >= 0) {
                if (nodes[current].value < nodes[minimum].value) {
                    minimum = current;
                    minimum_previous = previous;
                }
                previous = current;
                current = nodes[current].next;
            }
            checksum += (int64_t)(operation + 1) * (nodes[minimum].value + 1000001);
            if (minimum_previous < 0) front = nodes[minimum].next;
            else nodes[minimum_previous].next = nodes[minimum].next;
            if (rear == minimum) rear = minimum_previous;
            nodes[minimum].next = free_head;
            free_head = minimum;
        } else return -1;
    }

    size_t position = 1;
    for (int node = front; node >= 0; node = nodes[node].next, ++position)
        checksum += (int64_t)position * (nodes[node].value + 1000001);
    return checksum;
}
