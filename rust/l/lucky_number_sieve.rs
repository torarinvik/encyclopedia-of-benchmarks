const MAX_CANDIDATES: usize = 2048;

#[no_mangle]
pub unsafe extern "C" fn lucky_number_sieve(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 2 {
        return -1;
    }
    let mode = *input;
    let bound = *input.add(1);
    if (mode != 0 && mode != 1) || !(0..=4096).contains(&bound) {
        return -1;
    }

    let mut candidates = [0i64; MAX_CANDIDATES];
    let mut count = 0usize;
    let mut value = if mode == 0 { 1 } else { 2 };
    while value <= bound {
        candidates[count] = value;
        count += 1;
        value += 2;
    }

    let mut selected = 1usize;
    while selected < count {
        let step = candidates[selected] as usize;
        if step > count {
            break;
        }
        let mut write = 0usize;
        let mut rank = 0usize;
        for read in 0..count {
            rank += 1;
            if rank % step != 0 {
                candidates[write] = candidates[read];
                write += 1;
            }
        }
        count = write;
        selected += 1;
    }

    let output_bytes = count * 8;
    if output.is_null() || output_capacity < output_bytes {
        return -2;
    }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..count {
        let bytes = candidates[index].to_le_bytes();
        output_slice[index * 8..index * 8 + 8].copy_from_slice(&bytes);
    }
    output_bytes as i64
}
