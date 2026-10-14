/// Deterministic bogo sort for the shared, bounded portable workload.
#[no_mangle]
pub extern "C" fn bogo_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let mut state = 2_654_435_769_u64;
    while !values.windows(2).all(|pair| pair[0] <= pair[1]) {
        for index in (1..length).rev() {
            state = (state * 1_664_525 + 1_013_904_223) % 4_294_967_296;
            let other = ((state / 65_536) % (index as u64 + 1)) as usize;
            values.swap(index, other);
        }
    }
}
