use std::slice;

#[no_mangle]
pub unsafe extern "C" fn exponential_histogram_window(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=130).contains(&length) { return -1; }
    let values = unsafe { slice::from_raw_parts(input, length) };
    if !(1..=64).contains(&values[0]) || !(0..=128).contains(&values[1]) { return -1; }
    let (window, n) = (values[0] as usize, values[1] as usize);
    if length != n+2 || values[2..].iter().any(|&bit| bit != 0 && bit != 1) { return -1; }
    if output.is_null() || capacity < 8*n { return -2; }
    let out = unsafe { slice::from_raw_parts_mut(output, 8*n) };
    let mut buckets: Vec<(usize, usize)> = Vec::with_capacity(128);
    for (time, &bit) in values[2..].iter().enumerate() {
        if time >= window { buckets.retain(|&(end, _)| end > time-window); }
        if bit == 1 { buckets.push((time, 1)); }
        let mut size = 1;
        while size <= 128 {
            let mut positions = buckets.iter().enumerate().filter(|(_, bucket)| bucket.1 == size).map(|(i, _)| i);
            let first = positions.next();
            let second = positions.next();
            let third = positions.next();
            if let (Some(old), Some(new), Some(_)) = (first, second, third) {
                buckets[new].1 = 2*size;
                buckets.remove(old);
            }
            size *= 2;
        }
        let total: usize = buckets.iter().map(|bucket| bucket.1).sum();
        let estimate = 2*total - buckets.first().map_or(0, |bucket| bucket.1);
        out[8*time..8*time+8].copy_from_slice(&(estimate as i64).to_le_bytes());
    }
    (8*n) as i64
}
