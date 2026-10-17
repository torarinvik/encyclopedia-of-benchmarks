const MAX_INITIAL_ITEMS: usize = 32;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 162;
const MAX_STACK_SIZE: usize = MAX_INITIAL_ITEMS + MAX_OPERATIONS;
const MAX_OUTPUT_BYTES: usize = 16 * MAX_OPERATIONS;

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn list_based_stack(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);

    let raw_initial_count = values[0];
    if !(0..=MAX_INITIAL_ITEMS as i64).contains(&raw_initial_count) {
        return -1;
    }
    let initial_count = raw_initial_count as usize;
    let operation_count_index = 1 + initial_count;
    if operation_count_index >= length {
        return -1;
    }

    let mut initial_items = [0i64; MAX_INITIAL_ITEMS];
    for index in 0..initial_count {
        let value = values[1 + index];
        if value < i32::MIN as i64 || value > i32::MAX as i64 {
            return -1;
        }
        initial_items[index] = value;
    }

    let raw_operation_count = values[operation_count_index];
    if !(0..=MAX_OPERATIONS as i64).contains(&raw_operation_count) {
        return -1;
    }
    let operation_count = raw_operation_count as usize;
    let mut opcodes = [0i64; MAX_OPERATIONS];
    let mut arguments = [0i64; MAX_OPERATIONS];
    let mut cursor = operation_count_index + 1;
    let mut validated_size = initial_count;
    for index in 0..operation_count {
        if cursor >= length {
            return -1;
        }
        let opcode = values[cursor];
        cursor += 1;
        opcodes[index] = opcode;
        if opcode == 1 || opcode == 5 {
            if cursor >= length {
                return -1;
            }
            let value = values[cursor];
            cursor += 1;
            if value < i32::MIN as i64 || value > i32::MAX as i64 {
                return -1;
            }
            arguments[index] = value;
            if opcode == 1 {
                validated_size += 1;
            }
        } else if opcode == 2 || opcode == 3 {
            if validated_size == 0 {
                return -1;
            }
            if opcode == 2 {
                validated_size -= 1;
            }
        } else if opcode == 4 {
            // Count leaves the stack unchanged.
        } else if opcode == 6 {
            validated_size = 0;
        } else {
            return -1;
        }
    }
    if cursor != length {
        return -1;
    }

    let mut stack = [0i64; MAX_STACK_SIZE];
    let mut stack_size = initial_count;
    for index in 0..initial_count {
        stack[index] = initial_items[index];
    }
    let mut buffer = [0u8; MAX_OUTPUT_BYTES];
    let mut written = 0usize;
    for index in 0..operation_count {
        let opcode = opcodes[index];
        let mut result = 0i64;
        if opcode == 1 {
            stack[stack_size] = arguments[index];
            stack_size += 1;
        } else if opcode == 2 {
            stack_size -= 1;
            result = stack[stack_size];
        } else if opcode == 3 {
            result = stack[stack_size - 1];
        } else if opcode == 4 {
            result = stack_size as i64;
        } else if opcode == 5 {
            result = if stack[..stack_size].contains(&arguments[index]) {
                1
            } else {
                0
            };
        } else {
            stack_size = 0;
        }
        put_i64_le(&mut buffer, written, opcode);
        put_i64_le(&mut buffer, written + 8, result);
        written += 16;
    }

    if output.is_null() || capacity < written {
        return -2;
    }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, written);
    written as i64
}
