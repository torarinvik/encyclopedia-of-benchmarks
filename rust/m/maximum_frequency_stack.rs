fn store_i64(out: &mut [u8], offset: usize, value: i64) {
    out[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn maximum_frequency_stack(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=130).contains(&length) { return -1; }
    let count = *input;
    if !(0..=64).contains(&count) || length != 1 + 2 * count as usize { return -1; }
    let mut frequency = [0i32; 17];
    let mut bucket_top = [-1i32; 65];
    let mut node_value = [0i64; 64];
    let mut node_next = [-1i32; 64];
    let mut popped = [0i64; 64];
    let (mut nodes, mut pop_count, mut position, mut maximum_frequency) = (0usize, 0usize, 1usize, 0usize);
    for _ in 0..count {
        let opcode = *input.add(position);
        let argument = *input.add(position + 1);
        position += 2;
        if opcode == 0 {
            if !(-8..=8).contains(&argument) { return -1; }
            let index = (argument + 8) as usize;
            frequency[index] += 1;
            let level = frequency[index] as usize;
            node_value[nodes] = argument;
            node_next[nodes] = bucket_top[level];
            bucket_top[level] = nodes as i32;
            nodes += 1;
            maximum_frequency = maximum_frequency.max(level);
        } else if opcode == 1 && argument == 0 {
            if maximum_frequency == 0 || bucket_top[maximum_frequency] < 0 { return -1; }
            let node = bucket_top[maximum_frequency] as usize;
            bucket_top[maximum_frequency] = node_next[node];
            let value = node_value[node];
            popped[pop_count] = value;
            pop_count += 1;
            frequency[(value + 8) as usize] -= 1;
            if bucket_top[maximum_frequency] < 0 { maximum_frequency -= 1; }
        } else { return -1; }
    }
    let needed = pop_count * 8;
    if needed != 0 && (output.is_null() || capacity < needed) { return -2; }
    if needed != 0 {
        let out = std::slice::from_raw_parts_mut(output, needed);
        for i in 0..pop_count { store_i64(out, i * 8, popped[i]); }
    }
    needed as i64
}
