const MAX_STEPS: usize = 32;
const MAX_OUTPUT_BYTES: usize = MAX_STEPS * 8;

fn store_i64_le(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output[offset + byte] = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn stormer_verlet_position(input: *const i64, length: usize,
                                                   output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_STEPS + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(2..=MAX_STEPS as i64).contains(&count_value) { return -1; }
    if length != count_value as usize + 1 { return -1; }
    if !(-1024..=1024).contains(&values[1]) || !(-1024..=1024).contains(&values[2]) {
        return -1;
    }
    let count = count_value as usize;
    if values[3..].iter().any(|term| !(-64..=64).contains(term)) { return -1; }

    let byte_count = 8 * count;
    if output.is_null() || capacity < byte_count { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    let mut previous = values[1];
    let mut current = values[2];
    store_i64_le(&mut staged, 0, previous);
    store_i64_le(&mut staged, 8, current);
    for index in 2..count {
        let next = 2 * current - previous + values[index + 1];
        store_i64_le(&mut staged, 8 * index, next);
        previous = current;
        current = next;
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, byte_count);
    byte_count as i64
}
