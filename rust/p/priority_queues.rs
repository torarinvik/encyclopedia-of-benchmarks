const MAX_CAPACITY: usize = 128;
const MAX_OPERATIONS: usize = 256;
const MAX_INPUT_VALUES: usize = 515;
const MAX_OUTPUT_BYTES: usize = 4096;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (byte, value) in bytes.iter().enumerate() {
        unsafe { *output.add(offset + byte) = *value; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn priority_queues(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let capacity_value = unsafe { *input };
    let operation_count_value = unsafe { *input.add(1) };
    if !(1..=MAX_CAPACITY as i64).contains(&capacity_value)
        || !(0..=MAX_OPERATIONS as i64).contains(&operation_count_value)
    {
        return -1;
    }

    let capacity = capacity_value as usize;
    let operation_count = operation_count_value as usize;
    if length != 2 + 2 * operation_count {
        return -1;
    }
    for operation in 0..operation_count {
        let opcode = unsafe { *input.add(2 + 2 * operation) };
        let argument = unsafe { *input.add(3 + 2 * operation) };
        if !(0..=5).contains(&opcode) {
            return -1;
        }
        if opcode == 0 {
            if argument < i32::MIN as i64 || argument > i32::MAX as i64 {
                return -1;
            }
        } else if argument != 0 {
            return -1;
        }
    }

    if operation_count == 0 {
        return 0;
    }
    let needed = operation_count * 16;
    if needed > MAX_OUTPUT_BYTES || output.is_null() || output_capacity < needed {
        return -2;
    }

    let mut heap = [0i32; MAX_CAPACITY + 1];
    let mut size = 0usize;
    for operation in 0..operation_count {
        let opcode = unsafe { *input.add(2 + 2 * operation) };
        let argument = unsafe { *input.add(3 + 2 * operation) };
        let mut status = 0i64;
        let mut value = 0i64;

        if opcode == 0 {
            if size == capacity {
                status = 1;
            } else {
                size += 1;
                heap[size] = argument as i32;
                let mut index = size;
                while index > 1 && heap[index / 2] < heap[index] {
                    heap.swap(index / 2, index);
                    index /= 2;
                }
            }
        } else if opcode == 1 {
            if size == 0 {
                status = 2;
            } else {
                value = heap[1] as i64;
                heap[1] = heap[size];
                heap[size] = 0;
                size -= 1;
                let mut index = 1usize;
                while index * 2 <= size {
                    let mut child = index * 2;
                    if child < size && heap[child + 1] > heap[child] {
                        child += 1;
                    }
                    if heap[index] >= heap[child] {
                        break;
                    }
                    heap.swap(index, child);
                    index = child;
                }
            }
        } else if opcode == 2 {
            value = if size == 0 { 0 } else { heap[1] as i64 };
        } else if opcode == 3 {
            value = if size == 0 { 1 } else { 0 };
        } else if opcode == 4 {
            value = if size == capacity { 1 } else { 0 };
        } else {
            value = size as i64;
        }

        unsafe {
            store_i64_le(output, operation * 16, status);
            store_i64_le(output, operation * 16 + 8, value);
        }
    }
    needed as i64
}
