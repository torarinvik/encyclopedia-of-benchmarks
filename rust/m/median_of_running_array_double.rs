const MAX_COUNT: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;

fn less_double(left: f64, right: f64) -> bool { left.total_cmp(&right).is_lt() }
fn push_max(heap: &mut [f64; MAX_COUNT], count: &mut usize, value: f64) {
    let mut position = *count; *count += 1;
    while position > 0 && less_double(heap[(position - 1) / 2], value) {
        let parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent;
    }
    heap[position] = value;
}
fn pop_max(heap: &mut [f64; MAX_COUNT], count: &mut usize) -> f64 {
    let result = heap[0]; *count -= 1; let value = heap[*count];
    if *count == 0 { return result; }
    let mut position = 0;
    while 2 * position + 1 < *count {
        let mut child = 2 * position + 1;
        if child + 1 < *count && less_double(heap[child], heap[child + 1]) { child += 1; }
        if !less_double(value, heap[child]) { break; }
        heap[position] = heap[child]; position = child;
    }
    heap[position] = value; result
}
fn push_min(heap: &mut [f64; MAX_COUNT], count: &mut usize, value: f64) {
    let mut position = *count; *count += 1;
    while position > 0 && less_double(value, heap[(position - 1) / 2]) {
        let parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent;
    }
    heap[position] = value;
}
fn pop_min(heap: &mut [f64; MAX_COUNT], count: &mut usize) -> f64 {
    let result = heap[0]; *count -= 1; let value = heap[*count];
    if *count == 0 { return result; }
    let mut position = 0;
    while 2 * position + 1 < *count {
        let mut child = 2 * position + 1;
        if child + 1 < *count && less_double(heap[child + 1], heap[child]) { child += 1; }
        if !less_double(heap[child], value) { break; }
        heap[position] = heap[child]; position = child;
    }
    heap[position] = value; result
}

#[no_mangle]
pub unsafe extern "C" fn median_of_running_array_double(input: *const f64, length: usize,
                                                          output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !count_value.is_finite() || count_value < 1.0 || count_value > MAX_COUNT as f64 || count_value.fract() != 0.0 ||
        length != 1 + count_value as usize { return -1; }
    let count = count_value as usize;
    let mut lower = [0.0; MAX_COUNT]; let mut upper = [0.0; MAX_COUNT]; let mut medians = [0.0; MAX_COUNT];
    let mut lower_count = 0usize; let mut upper_count = 0usize;
    for i in 0..count {
        let sample = values[i + 1];
        if !sample.is_finite() || sample < -1_000_000.0 || sample > 1_000_000.0 { return -1; }
        if upper_count > 0 && less_double(sample, upper[0]) { push_max(&mut lower, &mut lower_count, sample); }
        else { push_min(&mut upper, &mut upper_count, sample); }
        if lower_count > upper_count + 1 { push_min(&mut upper, &mut upper_count, pop_max(&mut lower, &mut lower_count)); }
        else if upper_count > lower_count + 1 { push_max(&mut lower, &mut lower_count, pop_min(&mut upper, &mut upper_count)); }
        medians[i] = if lower_count > upper_count { lower[0] }
        else if upper_count > lower_count { upper[0] }
        else { (lower[0] + upper[0]) / 2.0 };
    }
    if output.is_null() || capacity < count { return -2; }
    for i in 0..count { *output.add(i) = medians[i]; }
    count as i64
}
