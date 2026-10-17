const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_OPERATIONS;
const MAX_DEPTH: usize = 64;
const MAX_OUTPUT_BYTES: usize = 4 + 8 * MAX_OPERATIONS;

#[no_mangle]
pub unsafe extern "C" fn linked_list_stack(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let words = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_OPERATIONS as i64).contains(&words[0]) {
        return -1;
    }

    let operation_count = words[0] as usize;
    let mut node_values = [0i32; MAX_DEPTH];
    let mut node_next = [-1i32; MAX_DEPTH];
    let mut records = [0i32; 2 * MAX_OPERATIONS];
    let mut node_count = 0usize;
    let mut query_count = 0usize;
    let mut cursor = 1usize;
    let mut top = -1i32;
    let mut stack_size = 0i32;

    for _ in 0..operation_count {
        if cursor >= length {
            return -1;
        }
        let opcode = words[cursor];
        cursor += 1;
        if opcode == 0 {
            if cursor >= length {
                return -1;
            }
            let value = words[cursor];
            cursor += 1;
            if value < i32::MIN as i64 || value > i32::MAX as i64
                || stack_size >= MAX_DEPTH as i32 || node_count >= MAX_DEPTH
            {
                return -1;
            }
            node_values[node_count] = value as i32;
            node_next[node_count] = top;
            top = node_count as i32;
            node_count += 1;
            stack_size += 1;
        } else if opcode == 1 {
            if stack_size == 0 || top < 0 {
                return -1;
            }
            records[2 * query_count] = 1;
            records[2 * query_count + 1] = node_values[top as usize];
            query_count += 1;
            top = node_next[top as usize];
            stack_size -= 1;
        } else if opcode == 2 {
            records[2 * query_count] = 2;
            records[2 * query_count + 1] = stack_size;
            query_count += 1;
        } else if opcode == 3 {
            records[2 * query_count] = 3;
            records[2 * query_count + 1] = if stack_size == 0 { 1 } else { 0 };
            query_count += 1;
        } else {
            return -1;
        }
    }
    if cursor != length {
        return -1;
    }

    let output_bytes = 4 + 8 * query_count;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    let mut buffer = [0u8; MAX_OUTPUT_BYTES];
    buffer[0..4].copy_from_slice(&(query_count as i32).to_le_bytes());
    for index in 0..2 * query_count {
        let offset = 4 + 4 * index;
        buffer[offset..offset + 4].copy_from_slice(&records[index].to_le_bytes());
    }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, output_bytes);
    output_bytes as i64
}
