const max_values = 1024;

fn nodeLess(values: []const i64, left: usize, right: usize) bool {
    return values[left] < values[right] or
        (values[left] == values[right] and left < right);
}

fn pushCandidate(values: []const i64, heap: []usize, heap_length: *usize, node: usize) void {
    var position = heap_length.*;
    heap_length.* += 1;
    heap[position] = node;
    while (position > 0) {
        const parent = (position - 1) / 2;
        if (!nodeLess(values, heap[position], heap[parent])) break;
        const temporary = heap[position];
        heap[position] = heap[parent];
        heap[parent] = temporary;
        position = parent;
    }
}

fn popCandidate(values: []const i64, heap: []usize, heap_length: *usize) usize {
    const minimum = heap[0];
    heap_length.* -= 1;
    if (heap_length.* == 0) return minimum;

    heap[0] = heap[heap_length.*];
    var position: usize = 0;
    while (position < heap_length.* / 2) {
        var child = position * 2 + 1;
        if (child + 1 < heap_length.* and nodeLess(values, heap[child + 1], heap[child])) {
            child += 1;
        }
        if (!nodeLess(values, heap[child], heap[position])) break;
        const temporary = heap[position];
        heap[position] = heap[child];
        heap[child] = temporary;
        position = child;
    }
    return minimum;
}

export fn adaptive_heap_sort(values: [*]i64, length: usize) void {
    if (length < 2 or length > max_values) return;
    const input = values[0..length];
    var left: [max_values]usize = undefined;
    var right: [max_values]usize = undefined;
    var construction_stack: [max_values]usize = undefined;
    var candidate_heap: [max_values]usize = undefined;
    var output: [max_values]i64 = undefined;

    var stack_length: usize = 0;
    for (0..length) |index| {
        left[index] = length;
        right[index] = length;
        var last = length;
        while (stack_length > 0 and input[construction_stack[stack_length - 1]] > input[index]) {
            stack_length -= 1;
            last = construction_stack[stack_length];
        }
        if (stack_length > 0) right[construction_stack[stack_length - 1]] = index;
        if (last < length) left[index] = last;
        construction_stack[stack_length] = index;
        stack_length += 1;
    }

    var heap_length: usize = 0;
    pushCandidate(input, candidate_heap[0..], &heap_length, construction_stack[0]);
    for (0..length) |output_index| {
        const node = popCandidate(input, candidate_heap[0..], &heap_length);
        output[output_index] = input[node];
        if (left[node] < length) pushCandidate(input, candidate_heap[0..], &heap_length, left[node]);
        if (right[node] < length) pushCandidate(input, candidate_heap[0..], &heap_length, right[node]);
    }
    for (0..length) |index| input[index] = output[index];
}
