module max_consecutive_ones

// Return the longest run of ones in a binary array.
@[export: 'max_consecutive_ones']
pub fn max_consecutive_ones(values &i64, length usize) i64 {
    if length > 4096 { return -1 }
    mut best := usize(0)
    mut run := usize(0)
    for index in 0 .. length {
        value := unsafe { values[index] }
        if value != 0 && value != 1 { return -1 }
        if value == 1 {
            run++
            if run > best { best = run }
        } else {
            run = 0
        }
    }
    return i64(best)
}
