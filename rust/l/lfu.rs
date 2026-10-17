const MIN_CAPACITY: usize = 2;
const MAX_CAPACITY: usize = 16;
const MAX_OPERATIONS: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_OPERATIONS;
const MAX_OUTPUT_WORDS: usize = 3 * MAX_OPERATIONS;

fn move_to_front(keys: &mut [i32; MAX_CAPACITY], values: &mut [i32; MAX_CAPACITY], index: usize) {
    let key = keys[index];
    let value = values[index];
    for i in (1..=index).rev() {
        keys[i] = keys[i - 1];
        values[i] = values[i - 1];
    }
    keys[0] = key;
    values[0] = value;
}

fn append(words: &mut [i64; MAX_OUTPUT_WORDS], count: &mut usize, value: i64) {
    words[*count] = value;
    *count += 1;
}

#[no_mangle]
pub unsafe extern "C" fn lfu(input: *const i64, length: usize,
                              output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    if !(MIN_CAPACITY as i64..=MAX_CAPACITY as i64).contains(&input[0]) ||
        !(0..=MAX_OPERATIONS as i64).contains(&input[1]) {
        return -1;
    }

    let cache_capacity = input[0] as usize;
    let operation_count = input[1] as usize;
    let mut keys = [0i32; MAX_CAPACITY];
    let mut values = [0i32; MAX_CAPACITY];
    let mut size = 0usize;
    let mut words = [0i64; MAX_OUTPUT_WORDS];
    let mut word_count = 0usize;
    let mut position = 2usize;

    for _ in 0..operation_count {
        if position >= length { return -1; }
        let opcode = input[position];
        position += 1;
        if opcode == 0 {
            if position + 1 >= length { return -1; }
            let key_arg = input[position];
            let value_arg = input[position + 1];
            position += 2;
            if key_arg < i32::MIN as i64 || key_arg > i32::MAX as i64 ||
                value_arg < i32::MIN as i64 || value_arg > i32::MAX as i64 { return -1; }
            let key = key_arg as i32;
            let mut index = 0usize;
            while index < size && keys[index] != key { index += 1; }
            if index < size {
                // The pinned Put mutates a copied item; the old value remains.
                move_to_front(&mut keys, &mut values, index);
            } else {
                if size == cache_capacity { size -= 1; }
                for i in (1..=size).rev() {
                    keys[i] = keys[i - 1];
                    values[i] = values[i - 1];
                }
                keys[0] = key;
                values[0] = value_arg as i32;
                size += 1;
            }
            append(&mut words, &mut word_count, 0);
        } else if opcode == 1 {
            if position >= length { return -1; }
            let key_arg = input[position];
            position += 1;
            if key_arg < i32::MIN as i64 || key_arg > i32::MAX as i64 { return -1; }
            let key = key_arg as i32;
            let mut index = 0usize;
            while index < size && keys[index] != key { index += 1; }
            append(&mut words, &mut word_count, 1);
            if index == size {
                append(&mut words, &mut word_count, 1);
                append(&mut words, &mut word_count, 0);
            } else {
                let value = values[index];
                move_to_front(&mut keys, &mut values, index);
                append(&mut words, &mut word_count, 0);
                append(&mut words, &mut word_count, value as i64);
            }
        } else {
            return -1;
        }
    }
    if position != length || word_count > MAX_OUTPUT_WORDS { return -1; }
    let output_length = word_count * 8;
    if output.is_null() || output_capacity < output_length { return -2; }
    for i in 0..word_count {
        let bytes = words[i].to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(i * 8), 8);
    }
    output_length as i64
}
