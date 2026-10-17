const MAX_COUNT: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; } }
}
fn push_max(heap: &mut [i64; MAX_COUNT], count: &mut usize, value: i64) {
    let mut position = *count; *count += 1;
    while position > 0 && heap[(position - 1) / 2] < value { let parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent; }
    heap[position] = value;
}
fn pop_max(heap: &mut [i64; MAX_COUNT], count: &mut usize) -> i64 {
    let result = heap[0]; *count -= 1; let value = heap[*count]; if *count == 0 { return result; }
    let mut position = 0;
    while 2 * position + 1 < *count { let mut child = 2 * position + 1; if child + 1 < *count && heap[child + 1] > heap[child] { child += 1; } if heap[child] <= value { break; } heap[position] = heap[child]; position = child; }
    heap[position] = value; result
}
fn push_min(heap: &mut [i64; MAX_COUNT], count: &mut usize, value: i64) {
    let mut position = *count; *count += 1;
    while position > 0 && heap[(position - 1) / 2] > value { let parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent; }
    heap[position] = value;
}
fn pop_min(heap: &mut [i64; MAX_COUNT], count: &mut usize) -> i64 {
    let result = heap[0]; *count -= 1; let value = heap[*count]; if *count == 0 { return result; }
    let mut position = 0;
    while 2 * position + 1 < *count { let mut child = 2 * position + 1; if child + 1 < *count && heap[child + 1] < heap[child] { child += 1; } if heap[child] >= value { break; } heap[position] = heap[child]; position = child; }
    heap[position] = value; result
}

#[no_mangle]
pub unsafe extern "C" fn median_of_running_array_long(input: *const i64, length: usize,
                                                        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if count_value < 1 || count_value > MAX_COUNT as i64 || length != 1 + count_value as usize { return -1; }
    let count = count_value as usize;
    let mut lower = [0i64; MAX_COUNT]; let mut upper = [0i64; MAX_COUNT]; let mut medians = [0i64; MAX_COUNT];
    let mut lower_count = 0usize; let mut upper_count = 0usize;
    for i in 0..count {
        let sample = values[i + 1];
        if sample < -4_611_686_018_427_387_904i64 || sample > 4_611_686_018_427_387_903i64 { return -1; }
        if upper_count > 0 && sample < upper[0] { push_max(&mut lower, &mut lower_count, sample); }
        else { push_min(&mut upper, &mut upper_count, sample); }
        if lower_count > upper_count + 1 { push_min(&mut upper, &mut upper_count, pop_max(&mut lower, &mut lower_count)); }
        else if upper_count > lower_count + 1 { push_max(&mut lower, &mut lower_count, pop_min(&mut upper, &mut upper_count)); }
        medians[i] = if lower_count > upper_count { lower[0] }
        else if upper_count > lower_count { upper[0] }
        else { (lower[0] + upper[0]) / 2 };
    }
    let output_bytes = count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for i in 0..count { store_i64_le(output, 8 * i, medians[i]); }
    output_bytes as i64
}
