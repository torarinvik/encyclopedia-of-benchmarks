const MAX_OPS: usize = 256;
const MAX_INPUT_LENGTH: usize = 770;

unsafe fn store_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn fixed_priority_queue_using_list(input: *const i64, length: usize,
                                                           output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(0..=MAX_OPS as i64).contains(&count_value) || length != 1 + 3 * count_value as usize { return -1; }
    let mut buckets = [[0i32; 100]; 3];
    let mut counts = [0usize; 3];
    let mut dequeued = [0i64; 128];
    let mut dequeued_count = 0usize;
    for i in 0..count_value as usize {
        let opcode = values[1 + 3 * i];
        let priority = values[2 + 3 * i];
        let data = values[3 + 3 * i];
        if opcode == 0 {
            if !(-3..=2).contains(&priority) || data < i32::MIN as i64 || data > i32::MAX as i64 { return -1; }
            let bucket = if priority < 0 { (priority + 3) as usize } else { priority as usize };
            if counts[bucket] == 100 { return -1; }
            buckets[bucket][counts[bucket]] = data as i32;
            counts[bucket] += 1;
        } else if opcode == 1 {
            if priority != 0 || data != 0 { return -1; }
            let mut bucket = 0usize;
            while bucket < 3 && counts[bucket] == 0 { bucket += 1; }
            if bucket == 3 { return -1; }
            dequeued[dequeued_count] = buckets[bucket][0] as i64;
            dequeued_count += 1;
            counts[bucket] -= 1;
            for j in 0..counts[bucket] { buckets[bucket][j] = buckets[bucket][j + 1]; }
        } else { return -1; }
    }
    let output_bytes = dequeued_count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for i in 0..dequeued_count { store_i64(output, i * 8, dequeued[i]); }
    output_bytes as i64
}
