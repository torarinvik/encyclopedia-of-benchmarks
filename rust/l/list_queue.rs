const MAX_QUEUE_SIZE: usize = 10;
const MAX_OPS: usize = 64;
const MAX_INPUT_LENGTH: usize = 129;
const MAX_OUTPUT_WORDS: usize = 130;

fn put_i32_le(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn list_queue(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_OPS as i64).contains(&values[0]) { return -1; }
    let op_count = values[0] as usize;
    let mut queue = [0i32; MAX_QUEUE_SIZE];
    let mut words = [0i32; MAX_OUTPUT_WORDS];
    let mut word_count = 1usize;
    let mut query_count = 0usize;
    let mut pos = 1usize;
    let mut queue_size = 0usize;
    for _ in 0..op_count {
        if pos >= length { return -1; }
        let opcode = values[pos];
        pos += 1;
        if opcode == 0 {
            if pos >= length { return -1; }
            let raw = values[pos];
            pos += 1;
            if raw < i32::MIN as i64 || raw > i32::MAX as i64 || queue_size >= MAX_QUEUE_SIZE { return -1; }
            queue[queue_size] = raw as i32;
            queue_size += 1;
        } else if opcode == 1 {
            if queue_size == 0 {
                words[word_count] = 3;
                words[word_count + 1] = 0;
                word_count += 2;
            } else {
                let value = queue[0];
                for i in 0..MAX_QUEUE_SIZE - 1 { queue[i] = queue[i + 1]; }
                queue_size -= 1;
                words[word_count] = 1;
                words[word_count + 1] = value;
                word_count += 2;
            }
            query_count += 1;
        } else if opcode == 2 {
            words[word_count] = 2;
            words[word_count + 1] = queue_size as i32;
            word_count += 2;
            query_count += 1;
        } else { return -1; }
    }
    if pos != length || word_count + 1 + queue_size > MAX_OUTPUT_WORDS { return -1; }
    words[0] = query_count as i32;
    words[word_count] = queue_size as i32;
    word_count += 1;
    for i in 0..queue_size {
        words[word_count] = queue[i];
        word_count += 1;
    }
    let bytes = word_count * 4;
    if output.is_null() || capacity < bytes { return -2; }
    let mut buffer = [0u8; MAX_OUTPUT_WORDS * 4];
    for i in 0..word_count { put_i32_le(&mut buffer, i * 4, words[i]); }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, bytes);
    bytes as i64
}
