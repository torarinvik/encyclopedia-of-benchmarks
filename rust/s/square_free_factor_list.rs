/// Check that an integer factor list has no repeated values.
#[no_mangle]
pub unsafe extern "C" fn square_free_factor_list(values: *const i64, length: usize) -> i64 {
    if length > 256 || (length != 0 && values.is_null()) {
        return -1;
    }
    for i in 0..length {
        let value = *values.add(i);
        if value < i32::MIN as i64 || value > i32::MAX as i64 {
            return -1;
        }
        for j in 0..i {
            if value == *values.add(j) {
                return 0;
            }
        }
    }
    1
}
