const MAX_LISTS: usize = 16;
const MAX_TOTAL_NODES: usize = 128;
const MAX_INPUT_LENGTH: usize = 1 + MAX_LISTS + MAX_TOTAL_NODES;
const MAX_OUTPUT_BYTES: usize = 4 * MAX_TOTAL_NODES;

#[derive(Clone, Copy)]
struct HeapNode {
    value: i64,
    list_index: usize,
    node_index: usize,
}

fn node_less(left: HeapNode, right: HeapNode) -> bool {
    (left.value, left.list_index, left.node_index)
        < (right.value, right.list_index, right.node_index)
}

fn heap_push(heap: &mut [HeapNode; MAX_LISTS], size: &mut usize, node: HeapNode) {
    let mut index = *size;
    *size += 1;
    while index > 0 {
        let parent = (index - 1) / 2;
        if !node_less(node, heap[parent]) {
            break;
        }
        heap[index] = heap[parent];
        index = parent;
    }
    heap[index] = node;
}

fn heap_pop(heap: &mut [HeapNode; MAX_LISTS], size: &mut usize) -> HeapNode {
    let result = heap[0];
    *size -= 1;
    let last = heap[*size];
    if *size > 0 {
        let mut index = 0;
        while index < *size / 2 {
            let mut child = 2 * index + 1;
            if child + 1 < *size && node_less(heap[child + 1], heap[child]) {
                child += 1;
            }
            if !node_less(heap[child], last) {
                break;
            }
            heap[index] = heap[child];
            index = child;
        }
        heap[index] = last;
    }
    result
}

fn put_i32_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 4].copy_from_slice(&(value as i32).to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn merge_ksorted_linked_list(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_LISTS as i64).contains(&values[0]) {
        return -1;
    }
    let list_count = values[0] as usize;
    let mut starts = [0usize; MAX_LISTS];
    let mut lengths = [0usize; MAX_LISTS];
    let mut position = 1usize;
    let mut total_nodes = 0usize;
    for list in 0..list_count {
        if position >= length {
            return -1;
        }
        let declared = values[position];
        position += 1;
        if declared < 0 || declared as u64 > (MAX_TOTAL_NODES - total_nodes) as u64 {
            return -1;
        }
        let list_length = declared as usize;
        if list_length > length - position {
            return -1;
        }
        starts[list] = position;
        lengths[list] = list_length;
        for node in 0..list_length {
            let value = values[position + node];
            if value < i32::MIN as i64 || value > i32::MAX as i64
                || (node > 0 && values[position + node - 1] > value)
            {
                return -1;
            }
        }
        position += list_length;
        total_nodes += list_length;
    }
    if position != length {
        return -1;
    }

    let output_bytes = 4 * total_nodes;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }

    let mut heap = [HeapNode { value: 0, list_index: 0, node_index: 0 }; MAX_LISTS];
    let mut heap_size = 0usize;
    for list in 0..list_count {
        if lengths[list] > 0 {
            heap_push(&mut heap, &mut heap_size, HeapNode {
                value: values[starts[list]], list_index: list, node_index: 0,
            });
        }
    }

    let mut buffer = [0u8; MAX_OUTPUT_BYTES];
    let mut written = 0usize;
    while heap_size > 0 {
        let node = heap_pop(&mut heap, &mut heap_size);
        put_i32_le(&mut buffer, written, node.value);
        written += 4;
        let next_index = node.node_index + 1;
        if next_index < lengths[node.list_index] {
            heap_push(&mut heap, &mut heap_size, HeapNode {
                value: values[starts[node.list_index] + next_index],
                list_index: node.list_index,
                node_index: next_index,
            });
        }
    }

    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, output_bytes);
    output_bytes as i64
}
