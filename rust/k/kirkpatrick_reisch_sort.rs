const MAX_ELEMENTS: usize = 256;
const MAX_BLOCKS: usize = 17;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 258;
const MAX_OUTPUT_BYTES: usize = 2048;

#[derive(Clone, Copy)]
struct HeapNode {
    value: i64,
    block: usize,
    offset: usize,
}

fn less(left: HeapNode, right: HeapNode) -> bool {
    (left.value, left.block, left.offset) < (right.value, right.block, right.offset)
}

fn heap_push(heap: &mut [HeapNode; MAX_BLOCKS], length: &mut usize, value: HeapNode) {
    let mut position = *length;
    *length += 1;
    while position > 0 {
        let parent = (position - 1) / 2;
        if !less(value, heap[parent]) {
            break;
        }
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = value;
}

fn heap_pop(heap: &mut [HeapNode; MAX_BLOCKS], length: &mut usize) -> HeapNode {
    let minimum = heap[0];
    *length -= 1;
    let last = heap[*length];
    if *length == 0 {
        return minimum;
    }
    let mut position = 0;
    while position * 2 + 1 < *length {
        let mut child = position * 2 + 1;
        if child + 1 < *length && less(heap[child + 1], heap[child]) {
            child += 1;
        }
        if !less(heap[child], last) {
            break;
        }
        heap[position] = heap[child];
        position = child;
    }
    heap[position] = last;
    minimum
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn kirkpatrick_reisch_sort(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[0] < 0 || values[0] > MAX_ELEMENTS as i64 {
        return -1;
    }
    let count = values[0] as usize;
    if input_length != count + 1 {
        return -1;
    }

    let mut blocks = [0_i64; MAX_ELEMENTS];
    blocks[..count].copy_from_slice(&values[1..]);
    let mut starts = [0_usize; MAX_BLOCKS];
    let mut lengths = [0_usize; MAX_BLOCKS];
    let mut block_count = 0;
    let mut block_size = 1;
    if count > 1 {
        while (block_size + 1) * (block_size + 1) <= count {
            block_size += 1;
        }
        let mut start = 0;
        while start < count {
            let length = (count - start).min(block_size);
            starts[block_count] = start;
            lengths[block_count] = length;
            block_count += 1;
            for index in 1..length {
                let value = blocks[start + index];
                let mut position = index;
                while position > 0 && blocks[start + position - 1] > value {
                    blocks[start + position] = blocks[start + position - 1];
                    position -= 1;
                }
                blocks[start + position] = value;
            }
            start += block_size;
        }
    } else if count == 1 {
        starts[0] = 0;
        lengths[0] = 1;
        block_count = 1;
    }

    let mut sorted = [0_i64; MAX_ELEMENTS];
    let mut sorted_count = 0;
    let mut heap = [HeapNode { value: 0, block: 0, offset: 0 }; MAX_BLOCKS];
    let mut heap_length = 0;
    for block in 0..block_count {
        heap_push(&mut heap, &mut heap_length, HeapNode { value: blocks[starts[block]], block, offset: 0 });
    }
    while heap_length > 0 {
        let current = heap_pop(&mut heap, &mut heap_length);
        sorted[sorted_count] = current.value;
        sorted_count += 1;
        let next = current.offset + 1;
        if next < lengths[current.block] {
            heap_push(&mut heap, &mut heap_length, HeapNode {
                value: blocks[starts[current.block] + next],
                block: current.block,
                offset: next,
            });
        }
    }

    let output_bytes = sorted_count * 8;
    if output_bytes > MAX_OUTPUT_BYTES {
        return -1;
    }
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..sorted_count {
        write_i64_le(output_slice, index * 8, sorted[index]);
    }
    output_bytes as i64
}
