#[no_mangle]
pub unsafe extern "C" fn reversort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = std::slice::from_raw_parts_mut(values, length);
    for index in 0..length - 1 {
        let mut minimum = index;
        for probe in index + 1..length {
            if values[probe] < values[minimum] {
                minimum = probe;
            }
        }
        values[index..=minimum].reverse();
    }
}
