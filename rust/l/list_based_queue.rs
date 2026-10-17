#[no_mangle]
pub extern "C" fn list_based_queue(input: *const i64, length: usize,
                                    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > 66 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 0 || values[0] > 32 { return -1; }
    let op_count = values[0] as usize;
    let (mut node_values, mut next_node) = ([0i32; 32], [-1i32; 32]);
    let mut words = [0i64; 64];
    let (mut allocated, mut word_count, mut pos, mut size) = (0usize, 0usize, 1usize, 0usize);
    let (mut head, mut tail) = (-1i32, -1i32);
    for _ in 0..op_count {
        if pos >= length { return -1; }
        let opcode = values[pos]; pos += 1;
        if opcode == 0 {
            if pos >= length { return -1; }
            let value = values[pos]; pos += 1;
            if value < i32::MIN as i64 || value > i32::MAX as i64 || allocated >= 32 { return -1; }
            let node = allocated as i32; allocated += 1;
            node_values[node as usize] = value as i32;
            next_node[node as usize] = -1;
            if tail < 0 { head = node; }
            else { next_node[tail as usize] = node; }
            tail = node; size += 1;
            words[word_count] = 0; words[word_count + 1] = 1; word_count += 2;
        } else if opcode == 1 {
            if head < 0 { return -1; }
            let node = head;
            head = next_node[node as usize];
            if head < 0 { tail = -1; }
            size -= 1;
            words[word_count] = 1; words[word_count + 1] = node_values[node as usize] as i64; word_count += 2;
        } else if opcode == 2 {
            if head < 0 { return -1; }
            words[word_count] = 2; words[word_count + 1] = node_values[head as usize] as i64; word_count += 2;
        } else if opcode == 3 {
            head = -1; tail = -1; size = 0;
            words[word_count] = 3; words[word_count + 1] = 1; word_count += 2;
        } else if opcode == 4 {
            words[word_count] = 4; words[word_count + 1] = if size == 0 { 1 } else { 0 }; word_count += 2;
        } else if opcode == 5 {
            words[word_count] = 5; words[word_count + 1] = 0; word_count += 2;
        } else { return -1; }
    }
    if pos != length || length > 1 + 2 * op_count || word_count > 64 { return -1; }
    let bytes = word_count * 8;
    if output.is_null() || output_capacity < bytes { return -2; }
    for (i, word) in words[..word_count].iter().enumerate() {
        let bits = *word as u64;
        for b in 0..8 { unsafe { *output.add(8 * i + b) = (bits >> (8 * b)) as u8; } }
    }
    bytes as i64
}
