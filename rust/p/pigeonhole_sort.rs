/// Portable pigeonhole sort for signed keys in [-128, 128].
#[no_mangle]
pub extern "C" fn pigeonhole_sort(values: *mut i64, scratch: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let scratch = unsafe { std::slice::from_raw_parts_mut(scratch, length + 257) };
    scratch[..257].fill(0);
    for index in 0..length {
        let bucket = (values[index] + 128) as usize;
        scratch[bucket] += 1;
    }
    let mut index = 0usize;
    for bucket in 0..257 {
        while scratch[bucket] > 0 {
            values[index] = bucket as i64 - 128;
            index += 1;
            scratch[bucket] -= 1;
        }
    }
}
