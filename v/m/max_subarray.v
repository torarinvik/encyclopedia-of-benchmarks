module max_subarray

fn max_subarray_range(values &i64, start usize, finish usize) i64 {
    if finish - start == 1 { return unsafe { values[start] } }
    middle := start + (finish - start) / 2
    left_best := max_subarray_range(values, start, middle)
    right_best := max_subarray_range(values, middle, finish)
    mut running := unsafe { values[middle - 1] }
    mut left_suffix := running
    mut index := middle - 1
    for index > start {
        index -= 1
        running += unsafe { values[index] }
        if running > left_suffix { left_suffix = running }
    }
    running = unsafe { values[middle] }
    mut right_prefix := running
    index = middle + 1
    for index < finish {
        running += unsafe { values[index] }
        if running > right_prefix { right_prefix = running }
        index += 1
    }
    crossing := left_suffix + right_prefix
    mut best := if left_best > right_best { left_best } else { right_best }
    if crossing > best { best = crossing }
    return best
}

@[export: 'max_subarray']
pub fn max_subarray(values &i64, length usize) i64 {
    if length == 0 || length > 1024 { return -1 }
    for index in 0 .. length {
        value := unsafe { values[index] }
        if value < -2147483648 || value > 2147483647 { return -1 }
    }
    return max_subarray_range(values, 0, length)
}
