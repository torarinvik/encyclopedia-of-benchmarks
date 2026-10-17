//! Sort signed i32 values by inserting into and draining a bounded min-heap.

const MAX_COUNT: usize = 128;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 130;

fn heap_push(heap: &mut [i32; MAX_COUNT], size: &mut usize, value: i32) {
    let mut child = *size;
    *size += 1;
    heap[child] = value;
    while child > 0 {
        let parent = (child - 1) / 2;
        if heap[parent] <= heap[child] {
            break;
        }
        heap.swap(parent, child);
        child = parent;
    }
}

fn heap_pop(heap: &mut [i32; MAX_COUNT], size: &mut usize) -> i32 {
    let minimum = heap[0];
    *size -= 1;
    if *size == 0 {
        return minimum;
    }
    heap[0] = heap[*size];
    let mut parent = 0;
    loop {
        let left = 2 * parent + 1;
        if left >= *size {
            break;
        }
        let right = left + 1;
        let smaller = if right < *size && heap[right] < heap[left] { right } else { left };
        if heap[parent] <= heap[smaller] {
            break;
        }
        heap.swap(parent, smaller);
        parent = smaller;
    }
    minimum
}

unsafe fn write_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn priority_queue_sort(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let raw_count = values[0];
    if raw_count < 0 || raw_count > MAX_COUNT as i64 || length != 1 + raw_count as usize {
        return -1;
    }
    let count = raw_count as usize;
    if values[1..].iter().any(|&value| value < i32::MIN as i64 || value > i32::MAX as i64) {
        return -1;
    }
    let byte_count = 4 * count;
    if output.is_null() || output_capacity < byte_count {
        return -2;
    }

    let mut heap = [0i32; MAX_COUNT];
    let mut heap_size = 0;
    for index in 0..count {
        heap_push(&mut heap, &mut heap_size, values[index + 1] as i32);
    }
    for index in 0..count {
        write_i32_le(output, 4 * index, heap_pop(&mut heap, &mut heap_size));
    }
    byte_count as i64
}
