const MAX_INPUT_LENGTH: usize = 99;
const MAX_OPERATIONS: usize = 32;
const MAX_CAPACITY: usize = 16;
const MAX_OUTPUT_FIELDS: usize = 114;

fn append(records: &mut [i64; MAX_OUTPUT_FIELDS], count: &mut usize, value: i64) {
    records[*count] = value;
    *count += 1;
}

fn execute(input: &[i64], records: &mut [i64; MAX_OUTPUT_FIELDS]) -> Result<usize, ()> {
    if input.len() < 2 || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let capacity = input[0];
    let operation_count = input[1];
    if !(2..=MAX_CAPACITY as i64).contains(&capacity)
        || !(0..=MAX_OPERATIONS as i64).contains(&operation_count)
        || input.len() != 2 + 3 * operation_count as usize { return Err(()); }
    let capacity = capacity as usize;
    let mut keys = [0i64; MAX_CAPACITY];
    let mut values = [0i64; MAX_CAPACITY];
    let mut seen = [0i64; MAX_OPERATIONS];
    let mut order = [0usize; MAX_CAPACITY];
    let (mut cache_count, mut seen_count, mut record_count, mut cursor) = (0usize, 0usize, 0usize, 2usize);

    for _ in 0..operation_count {
        let opcode = input[cursor];
        let key = input[cursor + 1];
        let value = input[cursor + 2];
        cursor += 3;
        if !(-1_000_000..=1_000_000).contains(&key) { return Err(()); }
        if opcode == 0 {
            if !(-1_000_000..=1_000_000).contains(&value) || seen[..seen_count].contains(&key) { return Err(()); }
            seen[seen_count] = key;
            seen_count += 1;
            let slot;
            if cache_count == capacity {
                slot = order[0];
                for index in 0..(cache_count - 1) { order[index] = order[index + 1]; }
                cache_count -= 1;
            } else {
                slot = cache_count;
            }
            keys[slot] = key;
            values[slot] = value;
            order[cache_count] = slot;
            cache_count += 1;
            append(records, &mut record_count, 0);
            append(records, &mut record_count, 0);
        } else if opcode == 1 {
            if value != 0 { return Err(()); }
            let position = order[..cache_count].iter().position(|&slot| keys[slot] == key).ok_or(())?;
            let slot = order[position];
            let cached_value = values[slot];
            for index in position..(cache_count - 1) { order[index] = order[index + 1]; }
            order[cache_count - 1] = slot;
            append(records, &mut record_count, 1);
            append(records, &mut record_count, 1);
            append(records, &mut record_count, cached_value);
        } else {
            return Err(());
        }
    }

    append(records, &mut record_count, 2);
    append(records, &mut record_count, cache_count as i64);
    for &slot in &order[..cache_count] {
        append(records, &mut record_count, keys[slot]);
        append(records, &mut record_count, values[slot]);
    }
    Ok(record_count)
}

#[no_mangle]
pub unsafe extern "C" fn lru(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mut records = [0i64; MAX_OUTPUT_FIELDS];
    let record_count = match execute(values, &mut records) { Ok(count) => count, Err(()) => return -1 };
    let output_bytes = record_count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for (index, record) in records[..record_count].iter().enumerate() {
        std::ptr::copy_nonoverlapping(record.to_le_bytes().as_ptr(), output.add(index * 8), 8);
    }
    output_bytes as i64
}
