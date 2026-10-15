module maximum_subarray

// Kadane's maximum nonempty contiguous-subarray sum.
@[export: 'maximum_subarray']
pub fn maximum_subarray(values &i64, length usize) i64 {
    if length == 0 || length > 1024 { return -1 }
    for index in 0 .. length {
        value := unsafe { values[index] }
        if value < -2147483648 || value > 2147483647 { return -1 }
    }
    mut current := unsafe { values[0] }
    mut best := current
    for index in 1 .. length {
        value := unsafe { values[index] }
        if current > 0 { current += value } else { current = value }
        if current > best { best = current }
    }
    return best
}
