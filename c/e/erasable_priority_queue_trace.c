#include <stddef.h>
#include <stdint.h>

enum { MAX_Q = 63, MAX_PARSEABLE_INPUT = 128, VALUE_OFFSET = 100, VALUE_COUNT = 201 };

static void heap_push(int heap[MAX_Q], int *size, int item) {
    int at = (*size)++;
    while (at > 0) {
        const int parent = (at - 1) / 2;
        if (heap[parent] <= item) break;
        heap[at] = heap[parent];
        at = parent;
    }
    heap[at] = item;
}

static int heap_pop(int heap[MAX_Q], int *size) {
    const int result = heap[0];
    const int last = heap[--(*size)];
    if (*size == 0) return result;
    int at = 0;
    for (;;) {
        int child = 2 * at + 1;
        if (child >= *size) break;
        if (child + 1 < *size && heap[child + 1] < heap[child]) ++child;
        if (heap[child] >= last) break;
        heap[at] = heap[child];
        at = child;
    }
    heap[at] = last;
    return result;
}

static void normalize(int live[MAX_Q], int *live_size,
                      int deleted[MAX_Q], int *deleted_size) {
    while (*live_size > 0 && *deleted_size > 0 && live[0] == deleted[0]) {
        heap_pop(live, live_size);
        heap_pop(deleted, deleted_size);
    }
}

int64_t erasable_priority_queue_trace(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_Q || length != 1 + 2 * (size_t)input[0]) return -1;
    const int q = (int)input[0];
    int count[VALUE_COUNT] = {0};
    int live[MAX_Q], deleted[MAX_Q];
    int live_size = 0, deleted_size = 0;
    int64_t score = 0;

    for (int operation = 0; operation < q; ++operation) {
        const int64_t opcode64 = input[1 + 2 * (size_t)operation];
        const int64_t operand64 = input[2 + 2 * (size_t)operation];
        if (opcode64 < 0 || opcode64 > 3 || operand64 < -100 || operand64 > 100) return -1;
        const int opcode = (int)opcode64, operand = (int)operand64;
        int response = 0;
        normalize(live, &live_size, deleted, &deleted_size);

        if (opcode == 0) {
            heap_push(live, &live_size, operand);
            ++count[operand + VALUE_OFFSET];
            normalize(live, &live_size, deleted, &deleted_size);
        } else if (opcode == 1) {
            const int key = operand + VALUE_OFFSET;
            if (count[key] == 0) return -1;
            --count[key];
            heap_push(deleted, &deleted_size, operand);
            response = 1;
            normalize(live, &live_size, deleted, &deleted_size);
        } else if (opcode == 2) {
            if (operand != 0) return -1;
            response = live_size == 0 ? -101 : live[0];
        } else {
            if (operand != 0 || live_size == 0) return -1;
            const int removed = heap_pop(live, &live_size);
            --count[removed + VALUE_OFFSET];
            response = removed;
        }
        const int token = opcode * 202 + response + 101;
        score += (int64_t)(operation + 1) * token;
    }
    return score;
}
