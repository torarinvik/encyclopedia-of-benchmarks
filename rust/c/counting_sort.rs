/// Counting sort for signed keys in the inclusive range [-128, 128].
#[no_mangle]
pub extern "C" fn counting_sort(values: *mut i64, counts: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let counts = unsafe { std::slice::from_raw_parts_mut(counts, 257) };
    counts.fill(0);
    for index in 0..length {
        let bucket = (values[index] + 128) as usize;
        counts[bucket] += 1;
    }
    let mut output = 0usize;
    for bucket in 0..257 {
        while counts[bucket] > 0 {
            values[output] = bucket as i64 - 128;
            output += 1;
            counts[bucket] -= 1;
        }
    }
}
