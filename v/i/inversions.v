module inversions
@[export: 'inversions']
pub fn inversions(values &i64, length usize) i64 {
    if length > 1024 { return -1 }
    if unsafe { values == nil } && length != 0 { return -1 }
    for i in 0 .. int(length) { if unsafe { values[i] < -2147483648 || values[i] > 2147483647 } { return -1 } }
    mut count := i64(0)
    for i in 0 .. int(length) { for j in i + 1 .. int(length) { if unsafe { values[i] > values[j] } { count++ } } }
    return count
}
