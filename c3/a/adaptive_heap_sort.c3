module adaptive_heap_sort;

const usz MAX_VALUES = 1024;

fn bool node_less(long* values, usz left, usz right) {
    return values[left] < values[right] || (values[left] == values[right] && left < right);
}

fn void push_candidate(long* values, usz* heap, usz* heap_length, usz node) {
    usz position = *heap_length;
    *heap_length += 1;
    heap[position] = node;
    while (position > 0) {
        usz parent = (position - 1) / 2;
        if (!node_less(values, heap[position], heap[parent])) break;
        usz temporary = heap[position];
        heap[position] = heap[parent];
        heap[parent] = temporary;
        position = parent;
    }
}

fn usz pop_candidate(long* values, usz* heap, usz* heap_length) {
    usz minimum = heap[0];
    *heap_length -= 1;
    if (*heap_length == 0) return minimum;
    heap[0] = heap[*heap_length];
    usz position = 0;
    while (position < *heap_length / 2) {
        usz child = position * 2 + 1;
        if (child + 1 < *heap_length && node_less(values, heap[child + 1], heap[child])) child += 1;
        if (!node_less(values, heap[child], heap[position])) break;
        usz temporary = heap[position];
        heap[position] = heap[child];
        heap[child] = temporary;
        position = child;
    }
    return minimum;
}

fn void adaptive_heap_sort(long* values, usz length) @export("adaptive_heap_sort") {
    if (values == null || length < 2 || length > MAX_VALUES) return;
    usz[MAX_VALUES] left;
    usz[MAX_VALUES] right;
    usz[MAX_VALUES] construction_stack;
    usz[MAX_VALUES] candidate_heap;
    long[MAX_VALUES] output;

    usz stack_length = 0;
    for (usz index = 0; index < length; index++) {
        left[index] = length;
        right[index] = length;
        usz last = length;
        while (stack_length > 0 && values[construction_stack[stack_length - 1]] > values[index]) {
            stack_length -= 1;
            last = construction_stack[stack_length];
        }
        if (stack_length > 0) right[construction_stack[stack_length - 1]] = index;
        if (last < length) left[index] = last;
        construction_stack[stack_length] = index;
        stack_length += 1;
    }

    usz heap_length = 0;
    push_candidate(values, &candidate_heap[0], &heap_length, construction_stack[0]);
    for (usz output_index = 0; output_index < length; output_index++) {
        usz node = pop_candidate(values, &candidate_heap[0], &heap_length);
        output[output_index] = values[node];
        if (left[node] < length) push_candidate(values, &candidate_heap[0], &heap_length, left[node]);
        if (right[node] < length) push_candidate(values, &candidate_heap[0], &heap_length, right[node]);
    }
    for (usz index = 0; index < length; index++) values[index] = output[index];
}
