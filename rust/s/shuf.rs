const MAX_INPUT_LENGTH: usize = 67;

fn write_i32_le(output: &mut [u8], index: usize, value: i32) {
    let offset = index * 4;
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn shuf(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_raw = values[0];
    let sample_size_raw = values[1];
    if !(0..=32).contains(&count_raw) || !(1..=32).contains(&sample_size_raw) { return -1; }
    let count = count_raw as usize;
    let sample_size = sample_size_raw as usize;
    if length != 2 + 2 * count { return -1; }

    let mut items = [0i32; 32];
    let mut sample = [0i32; 32];
    let mut occupied = [false; 32];
    for index in 0..count {
        let value = values[2 + index];
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        items[index] = value as i32;
    }
    let initial_count = count.min(sample_size);
    for index in 0..initial_count {
        let draw = values[2 + count + index];
        if draw < 0 || draw as u64 >= sample_size as u64 { return -1; }
        let mut slot = draw as usize;
        while occupied[slot] { slot = (slot + 1) % sample_size; }
        sample[slot] = items[index];
        occupied[slot] = true;
    }
    if count >= sample_size {
        for index in sample_size..count {
            let draw = values[2 + count + index];
            if draw < 0 || draw as u64 > index as u64 { return -1; }
            if draw < sample_size as i64 { sample[draw as usize] = items[index]; }
        }
    }

    let output_bytes = initial_count * 4;
    if output.is_null() || capacity < output_bytes { return -2; }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    let mut output_index = 0;
    for slot in 0..sample_size {
        if occupied[slot] {
            write_i32_le(output_slice, output_index, sample[slot]);
            output_index += 1;
        }
    }
    output_index as i64
}
