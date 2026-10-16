module min_max_heap_double_ended;

const usz MAX_INITIAL = 64;
const usz MAX_OPERATIONS = 128;
const usz MAX_HEAP_SIZE = 192;

fn bool is_min_level(usz index) {
    usz value = index + 1;
    usz depth = 0;
    while (value > 1) { value >>= 1; depth += 1; }
    return depth % 2 == 0;
}

fn void swap_values(long* heap, usz left, usz right) {
    long temporary = heap[left];
    heap[left] = heap[right];
    heap[right] = temporary;
}

fn int best_descendant(long* heap, usz count, usz index, bool find_min) {
    int best = -1;
    for (usz offset = 0; offset < 6; offset++) {
        usz candidate = offset < 2 ? 2 * index + 1 + offset : 4 * index + 1 + offset;
        if (candidate >= count) break;
        if (best < 0 || (find_min ? heap[candidate] < heap[(usz)best] : heap[candidate] > heap[(usz)best])) best = (int)candidate;
    }
    return best;
}

fn void push_down(long* heap, usz count, usz index, bool find_min) {
    while (index < count) {
        int found = best_descendant(heap, count, index, find_min);
        if (found < 0) return;
        usz best = (usz)found;
        bool grandchild = best > 2 && (best - 3) / 4 == index;
        bool improves = find_min ? heap[best] < heap[index] : heap[best] > heap[index];
        if (grandchild) {
            if (!improves) return;
            swap_values(heap, best, index);
            usz parent = (best - 1) / 2;
            bool violation = find_min ? heap[best] > heap[parent] : heap[best] < heap[parent];
            if (violation) swap_values(heap, best, parent);
            index = best;
        } else {
            if (improves) swap_values(heap, best, index);
            return;
        }
    }
}

fn void push_up_min(long* heap, usz index) {
    while (index > 2) {
        usz grandparent = (index - 3) / 4;
        if (heap[index] >= heap[grandparent]) return;
        swap_values(heap, index, grandparent);
        index = grandparent;
    }
}

fn void push_up_max(long* heap, usz index) {
    while (index > 2) {
        usz grandparent = (index - 3) / 4;
        if (heap[index] <= heap[grandparent]) return;
        swap_values(heap, index, grandparent);
        index = grandparent;
    }
}

fn void push_up(long* heap, usz index) {
    if (index == 0) return;
    usz parent = (index - 1) / 2;
    if (is_min_level(index)) {
        if (heap[index] > heap[parent]) { swap_values(heap, index, parent); push_up_max(heap, parent); }
        else push_up_min(heap, index);
    } else if (heap[index] < heap[parent]) { swap_values(heap, index, parent); push_up_min(heap, parent); }
    else push_up_max(heap, index);
}

fn void add_value(long* heap, usz* count, long value) {
    usz index = *count;
    *count += 1;
    heap[index] = value;
    push_up(heap, index);
}

fn usz max_index(long* heap, usz count) {
    if (count < 2) return 0;
    if (count == 2) return 1;
    return heap[1] > heap[2] ? 1 : 2;
}

fn long extract_at(long* heap, usz* count, usz index) {
    long result = heap[index];
    *count -= 1;
    if (index != *count) heap[index] = heap[*count];
    if (*count != 0 && index < *count) push_down(heap, *count, index, is_min_level(index));
    return result;
}

fn void write_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn void insertion_sort(long* values, usz count) {
    for (usz index = 1; index < count; index++) {
        long value = values[index];
        usz position = index;
        while (position > 0 && values[position - 1] > value) { values[position] = values[position - 1]; position -= 1; }
        values[position] = value;
    }
}

fn long min_max_heap_double_ended(long* input, usz length, char* output, usz capacity)
    @export("min_max_heap_double_ended") {
    if (input == null || length < 2) return -1;
    long initial_value = input[0];
    if (initial_value < 0 || initial_value > (long)MAX_INITIAL) return -1;
    usz initial_count = (usz)initial_value;
    if (length < initial_count + 2) return -1;
    long operations_value = input[initial_count + 1];
    if (operations_value < 0 || operations_value > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)operations_value;
    if (length != initial_count + 2 + 2 * operation_count) return -1;
    for (usz index = 0; index < initial_count; index++)
        if (input[index + 1] < -2147483648 || input[index + 1] > 2147483647) return -1;
    for (usz index = 0; index < operation_count; index++) {
        long opcode = input[initial_count + 2 + 2 * index];
        long argument = input[initial_count + 3 + 2 * index];
        if (opcode < 0 || opcode > 5) return -1;
        if (opcode == 0) { if (argument < -2147483648 || argument > 2147483647) return -1; }
        else if (argument != 0) return -1;
    }

    long[MAX_HEAP_SIZE] heap;
    usz count = initial_count;
    for (usz index = 0; index < initial_count; index++) heap[index] = input[index + 1];
    for (usz index = initial_count / 2; index > 0; index--) push_down(&heap[0], count, index - 1, is_min_level(index - 1));
    long[MAX_OPERATIONS] events;
    usz event_count = 0;
    for (usz op = 0; op < operation_count; op++) {
        long opcode = input[initial_count + 2 + 2 * op];
        long argument = input[initial_count + 3 + 2 * op];
        if (opcode == 0) add_value(&heap[0], &count, argument);
        else if (opcode == 1 || opcode == 3) {
            if (count == 0) return -1;
            events[event_count] = opcode == 1 ? heap[0] : extract_at(&heap[0], &count, 0);
            event_count += 1;
        } else if (opcode == 2 || opcode == 4) {
            if (count == 0) return -1;
            usz index = max_index(&heap[0], count);
            events[event_count] = opcode == 2 ? heap[index] : extract_at(&heap[0], &count, index);
            event_count += 1;
        } else { events[event_count] = (long)count; event_count += 1; }
    }
    long[MAX_HEAP_SIZE] sorted;
    for (usz index = 0; index < count; index++) sorted[index] = heap[index];
    insertion_sort(&sorted[0], count);
    usz required = (2 + event_count + count) * 8;
    if (output == null || capacity < required) return -2;
    usz offset = 0;
    write_i64(output, offset, (long)event_count); offset += 8;
    for (usz index = 0; index < event_count; index++) { write_i64(output, offset, events[index]); offset += 8; }
    write_i64(output, offset, (long)count); offset += 8;
    for (usz index = 0; index < count; index++) { write_i64(output, offset, sorted[index]); offset += 8; }
    return (long)required;
}
