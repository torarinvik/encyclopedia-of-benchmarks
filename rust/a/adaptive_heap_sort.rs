const MAX_VALUES: usize = 1024;

fn node_less(values: &[i64], left: usize, right: usize) -> bool {
    values[left] < values[right] || (values[left] == values[right] && left < right)
}

fn push_candidate(values: &[i64], heap: &mut [usize], heap_length: &mut usize, node: usize) {
    let mut position = *heap_length;
    *heap_length += 1;
    heap[position] = node;
    while position > 0 {
        let parent = (position - 1) / 2;
        if !node_less(values, heap[position], heap[parent]) {
            break;
        }
        heap.swap(position, parent);
        position = parent;
    }
}

fn pop_candidate(values: &[i64], heap: &mut [usize], heap_length: &mut usize) -> usize {
    let minimum = heap[0];
    *heap_length -= 1;
    if *heap_length == 0 {
        return minimum;
    }

    heap[0] = heap[*heap_length];
    let mut position = 0;
    while position < *heap_length / 2 {
        let mut child = position * 2 + 1;
        if child + 1 < *heap_length && node_less(values, heap[child + 1], heap[child]) {
            child += 1;
        }
        if !node_less(values, heap[child], heap[position]) {
            break;
        }
        heap.swap(position, child);
        position = child;
    }
    minimum
}

#[no_mangle]
pub unsafe extern "C" fn adaptive_heap_sort(values: *mut i64, length: usize) {
    if values.is_null() || length < 2 || length > MAX_VALUES {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let mut left = [length; MAX_VALUES];
    let mut right = [length; MAX_VALUES];
    let mut construction_stack = [0usize; MAX_VALUES];
    let mut candidate_heap = [0usize; MAX_VALUES];
    let mut output = [0i64; MAX_VALUES];

    let mut stack_length = 0;
    for index in 0..length {
        let mut last = length;
        while stack_length > 0 && values[construction_stack[stack_length - 1]] > values[index] {
            stack_length -= 1;
            last = construction_stack[stack_length];
        }
        if stack_length > 0 {
            right[construction_stack[stack_length - 1]] = index;
        }
        if last < length {
            left[index] = last;
        }
        construction_stack[stack_length] = index;
        stack_length += 1;
    }

    let mut heap_length = 0;
    push_candidate(values, &mut candidate_heap, &mut heap_length, construction_stack[0]);
    for output_index in 0..length {
        let node = pop_candidate(values, &mut candidate_heap, &mut heap_length);
        output[output_index] = values[node];
        if left[node] < length {
            push_candidate(values, &mut candidate_heap, &mut heap_length, left[node]);
        }
        if right[node] < length {
            push_candidate(values, &mut candidate_heap, &mut heap_length, right[node]);
        }
    }
    values.copy_from_slice(&output[..length]);
}
