const INVALID_RESULT: i64 = -1;
const CAPACITY_RESULT: i64 = -2;

#[no_mangle]
pub unsafe extern "C" fn booths_algorithm(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length == 0 || length > 256 {
        return INVALID_RESULT;
    }
    for index in 0..length {
        let value = *values.add(index);
        if !(0..=127).contains(&value) {
            return INVALID_RESULT;
        }
    }
    if output.is_null() || capacity < length {
        return CAPACITY_RESULT;
    }

    let mut failure = [-1_i64; 512];
    let mut start = 0_usize;
    for j in 1..(2 * length) {
        let current = *values.add(j % length);
        let mut matched = failure[j - start - 1];
        while matched != -1 && current != *values.add((start + matched as usize + 1) % length) {
            if current < *values.add((start + matched as usize + 1) % length) {
                start = j - matched as usize - 1;
            }
            matched = failure[matched as usize];
        }
        if matched == -1 && current != *values.add(start % length) {
            if current < *values.add(start % length) {
                start = j;
            }
            failure[j - start] = -1;
        } else {
            failure[j - start] = matched + 1;
        }
    }

    for index in 0..length {
        *output.add(index) = *values.add((start + index) % length) as u8;
    }
    length as i64
}
