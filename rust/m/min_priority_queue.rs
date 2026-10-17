const MAX_CAPACITY: usize = 64;
const MAX_OPS: usize = 64;
const MAX_INPUT_LENGTH: usize = 130;
const MAX_OUTPUT_WORDS: usize = 1 + 2 * MAX_OPS;

fn put_i32_le(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn min_priority_queue(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_CAPACITY as i64).contains(&values[0]) ||
        !(0..=MAX_OPS as i64).contains(&values[1]) { return -1; }

    let capacity = values[0] as usize;
    let operation_count = values[1] as usize;
    let mut heap = [0i32; MAX_CAPACITY];
    let mut words = [0i32; MAX_OUTPUT_WORDS];
    let mut heap_size = 0usize;
    let mut word_count = 1usize;
    let mut query_count = 0usize;
    let mut pos = 2usize;

    for _ in 0..operation_count {
        if pos >= length { return -1; }
        let opcode = values[pos];
        pos += 1;
        if opcode == 0 {
            if pos >= length { return -1; }
            let raw = values[pos];
            pos += 1;
            if raw < i32::MIN as i64 || raw > i32::MAX as i64 || heap_size >= capacity { return -1; }
            let mut index = heap_size;
            heap[index] = raw as i32;
            while index > 0 {
                let parent = (index - 1) / 2;
                if heap[parent] <= heap[index] { break; }
                heap.swap(parent, index);
                index = parent;
            }
            heap_size += 1;
        } else if opcode == 1 || opcode == 2 {
            if heap_size == 0 { return -1; }
            let value = heap[0];
            if opcode == 2 {
                heap_size -= 1;
                if heap_size > 0 {
                    heap[0] = heap[heap_size];
                    let mut index = 0usize;
                    loop {
                        let left = 2 * index + 1;
                        if left >= heap_size { break; }
                        let right = left + 1;
                        let child = if right < heap_size && heap[right] < heap[left] { right } else { left };
                        if heap[index] <= heap[child] { break; }
                        heap.swap(index, child);
                        index = child;
                    }
                }
            }
            words[word_count] = if opcode == 1 { 1 } else { 2 };
            words[word_count + 1] = value;
            word_count += 2;
            query_count += 1;
        } else if opcode == 3 || opcode == 4 {
            words[word_count] = if opcode == 3 { 3 } else { 4 };
            words[word_count + 1] = if opcode == 3 {
                if heap_size == 0 { 1 } else { 0 }
            } else if heap_size == capacity { 1 } else { 0 };
            word_count += 2;
            query_count += 1;
        } else { return -1; }
    }

    if pos != length || word_count > MAX_OUTPUT_WORDS { return -1; }
    words[0] = query_count as i32;
    let bytes = word_count * 4;
    if output.is_null() || output_capacity < bytes { return -2; }
    let mut buffer = [0u8; MAX_OUTPUT_WORDS * 4];
    for i in 0..word_count { put_i32_le(&mut buffer, i * 4, words[i]); }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, bytes);
    bytes as i64
}
