fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn xor_linked_list(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=66).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(0..=64).contains(&count_value) || length != count_value as usize + 1 {
        return -1;
    }
    let count = count_value as usize;
    if values[1..].iter().any(|&value| value < i32::MIN as i64 || value > i32::MAX as i64) {
        return -1;
    }
    let needed = 8 + 8 * count;
    if output.is_null() || capacity < needed {
        return -2;
    }
    let result = std::slice::from_raw_parts_mut(output, needed);
    let mut node_values = [0i64; 65];
    let mut both = [0usize; 65];
    let mut tail = 0usize;
    for i in 0..count {
        let node_id = i + 1;
        node_values[node_id] = values[i + 1];
        both[node_id] = tail;
        if tail != 0 {
            both[tail] ^= node_id;
        }
        tail = node_id;
    }
    write_i64_le(result, 0, count_value);
    let (mut out, mut previous, mut current) = (8usize, 0usize, if count == 0 { 0 } else { 1 });
    while current != 0 {
        write_i64_le(result, out, node_values[current]);
        out += 8;
        let next = previous ^ both[current];
        previous = current;
        current = next;
    }
    needed as i64
}
