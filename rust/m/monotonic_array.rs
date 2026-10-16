#[no_mangle]
pub extern "C" fn is_monotonic(values: *const i64, length: usize) -> i64 {
    if length > 256 || (values.is_null() && length != 0) {
        return -1;
    }

    for i in 1..length {
        let current = unsafe { *values.add(i) };
        let previous = unsafe { *values.add(i - 1) };
        if previous > current {
            for j in 1..length {
                let next = unsafe { *values.add(j) };
                let prior = unsafe { *values.add(j - 1) };
                if prior < next {
                    return 0;
                }
            }
            return 1;
        }
    }
    1
}
