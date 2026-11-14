#[no_mangle]
pub unsafe extern "C" fn lossy_counting_summary(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(2..=66).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(2..=16).contains(&values[0]) || !(0..=64).contains(&values[1]) { return -1; }
    let width = values[0] as usize;
    let n = values[1] as usize;
    if length != 2+n || values[2..].iter().any(|x| !(0..=15).contains(x)) { return -1; }
    let mut count = [0_i64; 16];
    let mut error = [0_i64; 16];
    for i in 0..n {
        let item = values[2+i] as usize;
        let bucket = (i/width+1) as i64;
        if count[item] == 0 { error[item] = bucket-1; }
        count[item] += 1;
        if (i+1)%width == 0 {
            for j in 0..16 {
                if count[j] != 0 && count[j]+error[j] <= bucket { count[j] = 0; error[j] = 0; }
            }
        }
    }
    let active = count.iter().filter(|&&x| x != 0).count();
    let bytes = 8+24*active;
    if output.is_null() || capacity < bytes { return -2; }
    let mut offset = 0;
    for word in std::iter::once(active as i64).chain((0..16).filter(|&i| count[i] != 0).flat_map(|i| [i as i64, count[i], error[i]])) {
        let encoded = word.to_le_bytes();
        std::ptr::copy_nonoverlapping(encoded.as_ptr(), output.add(offset), 8);
        offset += 8;
    }
    bytes as i64
}
