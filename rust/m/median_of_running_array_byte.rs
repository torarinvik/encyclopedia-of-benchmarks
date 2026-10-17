const MAX_COUNT: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;

fn push_max(heap: &mut [i32; MAX_COUNT], count: &mut usize, value: i32) {
    let mut i = *count; *count += 1;
    while i > 0 && heap[(i - 1) / 2] < value { let parent = (i - 1) / 2; heap[i] = heap[parent]; i = parent; }
    heap[i] = value;
}
fn pop_max(heap: &mut [i32; MAX_COUNT], count: &mut usize) -> i32 {
    let result = heap[0]; *count -= 1; let value = heap[*count];
    if *count == 0 { return result; }
    let mut i = 0;
    while 2 * i + 1 < *count { let mut child = 2 * i + 1; if child + 1 < *count && heap[child + 1] > heap[child] { child += 1; } if heap[child] <= value { break; } heap[i] = heap[child]; i = child; }
    heap[i] = value; result
}
fn push_min(heap: &mut [i32; MAX_COUNT], count: &mut usize, value: i32) {
    let mut i = *count; *count += 1;
    while i > 0 && heap[(i - 1) / 2] > value { let parent = (i - 1) / 2; heap[i] = heap[parent]; i = parent; }
    heap[i] = value;
}
fn pop_min(heap: &mut [i32; MAX_COUNT], count: &mut usize) -> i32 {
    let result = heap[0]; *count -= 1; let value = heap[*count];
    if *count == 0 { return result; }
    let mut i = 0;
    while 2 * i + 1 < *count { let mut child = 2 * i + 1; if child + 1 < *count && heap[child + 1] < heap[child] { child += 1; } if heap[child] >= value { break; } heap[i] = heap[child]; i = child; }
    heap[i] = value; result
}

#[no_mangle]
pub unsafe extern "C" fn median_of_running_array_byte(input: *const i32, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(1..=MAX_COUNT as i32).contains(&count_value) || length != 1 + count_value as usize { return -1; }
    let count = count_value as usize;
    let mut lower = [0i32; MAX_COUNT];
    let mut upper = [0i32; MAX_COUNT];
    let mut medians = [0u8; MAX_COUNT];
    let mut lower_count = 0usize; let mut upper_count = 0usize;
    for i in 0..count {
        let sample = values[i + 1];
        if !(-128..=127).contains(&sample) { return -1; }
        if upper_count > 0 && sample < upper[0] { push_max(&mut lower, &mut lower_count, sample); }
        else { push_min(&mut upper, &mut upper_count, sample); }
        if lower_count > upper_count + 1 { let value = pop_max(&mut lower, &mut lower_count); push_min(&mut upper, &mut upper_count, value); }
        else if upper_count > lower_count + 1 { let value = pop_min(&mut upper, &mut upper_count); push_max(&mut lower, &mut lower_count, value); }
        let median = if lower_count > upper_count { lower[0] } else if upper_count > lower_count { upper[0] } else {
            let sum = lower[0] + upper[0];
            if sum < 0 { -((-sum) / 2) } else { sum / 2 }
        };
        medians[i] = median as i8 as u8;
    }
    if output.is_null() || capacity < count { return -2; }
    let out = std::slice::from_raw_parts_mut(output, count);
    out.copy_from_slice(&medians[..count]);
    count as i64
}
