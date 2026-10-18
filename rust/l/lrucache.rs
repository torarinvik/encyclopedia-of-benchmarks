/// Run bounded Java/JavaScript LRU cache traces and return operation records.
#[no_mangle]
pub unsafe extern "C" fn lrucache(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > 99 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    let capacity_value = values[0];
    let operation_count_value = values[1];
    if !(2..=16).contains(&capacity_value) || !(0..=32).contains(&operation_count_value) {
        return -1;
    }
    let capacity = capacity_value as usize;
    let operation_count = operation_count_value as usize;
    if input_length != 2 + 3 * operation_count {
        return -1;
    }

    let mut keys = [0i64; 16];
    let mut cached_values = [0i64; 16];
    let mut seen_put_keys = [0i64; 32];
    let mut operation_records = [0i64; 96];
    let mut used = 0usize;
    let mut seen_count = 0usize;

    for operation in 0..operation_count {
        let opcode = values[2 + 3 * operation];
        let key = values[3 + 3 * operation];
        let value = values[4 + 3 * operation];
        if opcode != 0 && opcode != 1 {
            return -1;
        }
        if !(0..=1_000_000).contains(&key) {
            return -1;
        }
        let mut returned_value = -1i64;
        let mut evicted_key = -1i64;
        let mut position = 0usize;
        while position < used && keys[position] != key {
            position += 1;
        }

        if opcode == 0 {
            if !(0..=1_000_000).contains(&value) {
                return -1;
            }
            if seen_put_keys[..seen_count].contains(&key) {
                return -1;
            }
            seen_put_keys[seen_count] = key;
            seen_count += 1;
            if used == capacity {
                evicted_key = keys[0];
                for index in 1..used {
                    keys[index - 1] = keys[index];
                    cached_values[index - 1] = cached_values[index];
                }
                used -= 1;
            }
            keys[used] = key;
            cached_values[used] = value;
            used += 1;
        } else {
            if value != 0 || position == used {
                return -1;
            }
            returned_value = cached_values[position];
            for index in position + 1..used {
                keys[index - 1] = keys[index];
                cached_values[index - 1] = cached_values[index];
            }
            keys[used - 1] = key;
            cached_values[used - 1] = returned_value;
        }
        operation_records[3 * operation] = opcode;
        operation_records[3 * operation + 1] = returned_value;
        operation_records[3 * operation + 2] = evicted_key;
    }

    let mut fields = [0i64; 130];
    let mut word_count = 0usize;
    fields[word_count] = operation_count_value;
    word_count += 1;
    for index in 0..3 * operation_count {
        fields[word_count] = operation_records[index];
        word_count += 1;
    }
    fields[word_count] = used as i64;
    word_count += 1;
    for index in (0..used).rev() {
        fields[word_count] = keys[index];
        fields[word_count + 1] = cached_values[index];
        word_count += 2;
    }

    let output_bytes = word_count * 8;
    if output.is_null() || output_capacity < output_bytes {
        return -2;
    }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..word_count {
        output_slice[index * 8..index * 8 + 8].copy_from_slice(&fields[index].to_le_bytes());
    }
    output_bytes as i64
}
