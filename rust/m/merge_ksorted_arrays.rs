const MAX_ARRAYS: usize = 16;
const MAX_TOTAL_VALUES: usize = 128;
const MAX_PARSEABLE_LENGTH: usize = 1 + MAX_ARRAYS + MAX_TOTAL_VALUES + 1;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;
const CHECKSUM_OFFSET: i64 = 1_000_001;

#[derive(Clone, Copy)]
struct HeapNode {
    value: i64,
    array_index: usize,
    element_index: usize,
}

fn node_less(left: HeapNode, right: HeapNode) -> bool {
    (left.value, left.array_index, left.element_index)
        < (right.value, right.array_index, right.element_index)
}

fn heap_push(heap: &mut [HeapNode; MAX_ARRAYS], size: &mut usize, node: HeapNode) {
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

fn heap_pop(heap: &mut [HeapNode; MAX_ARRAYS], size: &mut usize) -> HeapNode {
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

#[no_mangle]
pub unsafe extern "C" fn merge_ksorted_arrays(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    if !(1..=MAX_ARRAYS as i64).contains(&input[0]) {
        return -1;
    }
    let array_count = input[0] as usize;
    let mut starts = [0usize; MAX_ARRAYS];
    let mut lengths = [0usize; MAX_ARRAYS];
    let mut position = 1usize;
    let mut total_values = 0usize;
    for array in 0..array_count {
        if position >= length {
            return -1;
        }
        let declared = input[position];
        position += 1;
        if declared < 0 || declared as u64 > (MAX_TOTAL_VALUES - total_values) as u64 {
            return -1;
        }
        let array_length = declared as usize;
        if array_length > length - position {
            return -1;
        }
        starts[array] = position;
        lengths[array] = array_length;
        for index in 0..array_length {
            let value = input[position + index];
            if !(MIN_VALUE..=MAX_VALUE).contains(&value)
                || (index > 0 && input[position + index - 1] > value)
            {
                return -1;
            }
        }
        position += array_length;
        total_values += array_length;
    }
    if position != length {
        return -1;
    }

    let mut heap = [HeapNode { value: 0, array_index: 0, element_index: 0 }; MAX_ARRAYS];
    let mut heap_size = 0usize;
    for array in 0..array_count {
        if lengths[array] > 0 {
            heap_push(&mut heap, &mut heap_size, HeapNode {
                value: input[starts[array]], array_index: array, element_index: 0,
            });
        }
    }
    let mut checksum = 0i64;
    let mut merged_index = 0i64;
    while heap_size > 0 {
        let node = heap_pop(&mut heap, &mut heap_size);
        checksum += (merged_index + 1) * (node.value + CHECKSUM_OFFSET);
        merged_index += 1;
        let next_index = node.element_index + 1;
        if next_index < lengths[node.array_index] {
            heap_push(&mut heap, &mut heap_size, HeapNode {
                value: input[starts[node.array_index] + next_index],
                array_index: node.array_index,
                element_index: next_index,
            });
        }
    }
    checksum
}
