const MAX_OPS: usize = 64;

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() { *output.add(offset + index) = *byte; }
}

#[no_mangle]
pub unsafe extern "C" fn lifocache(input: *const i64, length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 2 + 3 * MAX_OPS { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let capacity_value = input[0];
    let operation_count_value = input[1];
    if !(1..=16).contains(&capacity_value) || !(1..=64).contains(&operation_count_value) { return -1; }
    let capacity = capacity_value as usize;
    let operations = operation_count_value as usize;
    if length != 2 + 3 * operations { return -1; }
    for i in 0..operations {
        let op = input[2 + 3 * i];
        let key = input[3 + 3 * i];
        let value = input[4 + 3 * i];
        if !(0..=6).contains(&op) { return -1; }
        if op <= 2 {
            if key < i32::MIN as i64 || key > i32::MAX as i64 { return -1; }
            if op == 0 {
                if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
            } else if value != 0 { return -1; }
        } else if key != 0 || value != 0 { return -1; }
    }
    let required = operations * 16;
    if output.is_null() || output_capacity < required { return -2; }
    let mut keys = [0i64; 16];
    let mut values = [0i64; 16];
    let mut count = 0usize;
    let mut hits = 0i64;
    let mut misses = 0i64;
    for i in 0..operations {
        let op = input[2 + 3 * i];
        let key = input[3 + 3 * i];
        let value = input[4 + 3 * i];
        let mut first = 0i64;
        let mut second = 0i64;
        if op == 0 {
            let mut found = count;
            for j in 0..count { if keys[j] == key { found = j; break; } }
            if found < count {
                let mut j = found;
                while j + 1 < count { keys[j] = keys[j + 1]; values[j] = values[j + 1]; j += 1; }
                count -= 1;
            }
            if count == capacity { count -= 1; }
            keys[count] = key; values[count] = value; count += 1; first = 1;
        } else if op == 1 {
            let mut found = count;
            for j in 0..count { if keys[j] == key { found = j; break; } }
            if found < count { hits += 1; first = 1; second = values[found]; } else { misses += 1; }
        } else if op == 2 {
            let mut found = count;
            for j in 0..count { if keys[j] == key { found = j; break; } }
            if found < count {
                first = 1; second = values[found];
                let mut j = found;
                while j + 1 < count { keys[j] = keys[j + 1]; values[j] = values[j + 1]; j += 1; }
                count -= 1;
            }
        } else if op == 3 { first = count as i64; }
        else if op == 4 { first = hits; }
        else if op == 5 { first = misses; }
        else { count = 0; hits = 0; misses = 0; first = 1; }
        put_i64_le(output, 16 * i, first);
        put_i64_le(output, 16 * i + 8, second);
    }
    (2 * operations) as i64
}
