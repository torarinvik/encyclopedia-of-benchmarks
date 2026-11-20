module erasable_priority_queue_trace;

const int MAX_Q = 63;
const int VALUE_OFFSET = 100;
const int VALUE_COUNT = 201;
const usz MAX_PARSEABLE_INPUT = 128;

fn void heap_push(int* heap, int* size, int item) {
    int at = *size;
    *size = *size + 1;
    while (at > 0) {
        int parent = (at - 1) / 2;
        if (heap[parent] <= item) break;
        heap[at] = heap[parent];
        at = parent;
    }
    heap[at] = item;
}

fn int heap_pop(int* heap, int* size) {
    int result = heap[0];
    *size = *size - 1;
    int last = heap[*size];
    if (*size == 0) return result;
    int at = 0;
    while (true) {
        int child = 2 * at + 1;
        if (child >= *size) break;
        if (child + 1 < *size && heap[child + 1] < heap[child]) child = child + 1;
        if (heap[child] >= last) break;
        heap[at] = heap[child];
        at = child;
    }
    heap[at] = last;
    return result;
}

fn void normalize(int* live, int* live_size, int* deleted, int* deleted_size) {
    while (*live_size > 0 && *deleted_size > 0 && live[0] == deleted[0]) {
        heap_pop(live, live_size);
        heap_pop(deleted, deleted_size);
    }
}

fn long erasable_priority_queue_trace(long* input, usz length) @export("erasable_priority_queue_trace") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_Q || length != (usz)(1 + 2 * input[0])) return -1;
    int q = (int)input[0];
    int[VALUE_COUNT] count = zeroed;
    int[MAX_Q] live, deleted;
    int live_size = 0, deleted_size = 0;
    long score = 0;

    for (int operation = 0; operation < q; operation++) {
        long opcode_raw = input[1 + 2 * (usz)operation];
        long operand_raw = input[2 + 2 * (usz)operation];
        if (opcode_raw < 0 || opcode_raw > 3 || operand_raw < -100 || operand_raw > 100) return -1;
        int opcode = (int)opcode_raw, operand = (int)operand_raw;
        int response = 0;
        normalize(&live[0], &live_size, &deleted[0], &deleted_size);

        if (opcode == 0) {
            heap_push(&live[0], &live_size, operand);
            count[operand + VALUE_OFFSET] = count[operand + VALUE_OFFSET] + 1;
            normalize(&live[0], &live_size, &deleted[0], &deleted_size);
        } else if (opcode == 1) {
            int key = operand + VALUE_OFFSET;
            if (count[key] == 0) return -1;
            count[key] = count[key] - 1;
            heap_push(&deleted[0], &deleted_size, operand);
            response = 1;
            normalize(&live[0], &live_size, &deleted[0], &deleted_size);
        } else if (opcode == 2) {
            if (operand != 0) return -1;
            response = live_size == 0 ? -101 : live[0];
        } else {
            if (operand != 0 || live_size == 0) return -1;
            int removed = heap_pop(&live[0], &live_size);
            count[removed + VALUE_OFFSET] = count[removed + VALUE_OFFSET] - 1;
            response = removed;
        }
        int token = opcode * 202 + response + 101;
        score = score + (long)(operation + 1) * token;
    }
    return score;
}
