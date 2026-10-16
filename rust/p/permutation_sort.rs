const MAX_LENGTH: usize = 8;
const INVALID_RESULT: i64 = -1;

fn is_sorted(values: &[i64]) -> bool {
    values.windows(2).all(|pair| pair[0] <= pair[1])
}

#[no_mangle]
pub unsafe extern "C" fn permutation_sort(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > MAX_LENGTH {
        return INVALID_RESULT;
    }
    let input = std::slice::from_raw_parts(values, length);
    let mut working = [0_i64; MAX_LENGTH];
    working[..length].copy_from_slice(input);
    let mut counters = [0_usize; MAX_LENGTH];

    let mut checked = 1_i64;
    if is_sorted(&working[..length]) {
        return checked;
    }

    let mut index = 0;
    while index < length {
        if counters[index] < index {
            let swap_index = if index % 2 == 0 { 0 } else { counters[index] };
            working.swap(swap_index, index);
            counters[index] += 1;
            checked += 1;
            if is_sorted(&working[..length]) {
                return checked;
            }
            index = 0;
        } else {
            counters[index] = 0;
            index += 1;
        }
    }
    INVALID_RESULT
}
