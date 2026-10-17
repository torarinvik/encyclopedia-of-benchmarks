const MAX_OPS: usize = 256;
const MAX_INPUT_LENGTH: usize = 514;

unsafe fn store_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn element_priority_queue_using_list(input: *const i64, length: usize,
                                                              output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(0..=MAX_OPS as i64).contains(&count_value) || length != 1 + 2 * count_value as usize { return -1; }
    let mut queue = [0i32; 100];
    let mut queue_count = 0usize;
    let mut dequeued = [0i64; 128];
    let mut dequeued_count = 0usize;
    for i in 0..count_value as usize {
        let opcode = values[1 + 2 * i];
        let argument = values[2 + 2 * i];
        if opcode == 0 {
            if argument < i32::MIN as i64 || argument > i32::MAX as i64 || queue_count == 100 { return -1; }
            queue[queue_count] = argument as i32;
            queue_count += 1;
        } else if opcode == 1 {
            if argument != 0 || queue_count == 0 { return -1; }
            let mut minimum = 0usize;
            for j in 1..queue_count { if queue[j] < queue[minimum] { minimum = j; } }
            dequeued[dequeued_count] = queue[minimum] as i64;
            dequeued_count += 1;
            queue_count -= 1;
            for j in minimum..queue_count { queue[j] = queue[j + 1]; }
        } else { return -1; }
    }
    let output_bytes = dequeued_count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for i in 0..dequeued_count { store_i64(output, i * 8, dequeued[i]); }
    output_bytes as i64
}
