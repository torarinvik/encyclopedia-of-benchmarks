/// Find twice the median by binary-searching a partition of the shorter sorted array.
const MAX_ARRAY_LENGTH: usize = 1000;

#[no_mangle]
pub extern "C" fn median_of_two_sorted_arrays_partition(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > 2 * MAX_ARRAY_LENGTH + 2 { return -2_000_001; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 0 || values[0] > MAX_ARRAY_LENGTH as i64 ||
        values[1] < 0 || values[1] > MAX_ARRAY_LENGTH as i64 { return -2_000_001; }

    let first_count = values[0] as usize;
    let second_count = values[1] as usize;
    let total_count = first_count + second_count;
    if total_count == 0 || total_count > 2 * MAX_ARRAY_LENGTH || length != total_count + 2 { return -2_000_001; }
    let second_start = first_count + 2;
    let mut short_start = 2;
    let mut long_start = second_start;
    let mut short_count = first_count;
    let mut long_count = second_count;
    for index in 0..first_count {
        let value = values[index + 2];
        if value < -1_000_000 || value > 1_000_000 ||
            (index > 0 && values[index + 1] > value) { return -2_000_001; }
    }
    for index in 0..second_count {
        let value = values[second_start + index];
        if value < -1_000_000 || value > 1_000_000 ||
            (index > 0 && values[second_start + index - 1] > value) { return -2_000_001; }
    }

    if short_count > long_count {
        std::mem::swap(&mut short_start, &mut long_start);
        std::mem::swap(&mut short_count, &mut long_count);
    }
    let mut low_cut = 0usize;
    let mut high_cut = short_count;
    let left_count = (total_count + 1) / 2;
    while low_cut <= high_cut {
        let first_cut = low_cut + (high_cut - low_cut) / 2;
        let second_cut = left_count - first_cut;
        let first_left = if first_cut == 0 { i64::MIN } else { values[short_start + first_cut - 1] };
        let first_right = if first_cut == short_count { i64::MAX } else { values[short_start + first_cut] };
        let second_left = if second_cut == 0 { i64::MIN } else { values[long_start + second_cut - 1] };
        let second_right = if second_cut == long_count { i64::MAX } else { values[long_start + second_cut] };

        if first_left <= second_right && second_left <= first_right {
            let left_max = first_left.max(second_left);
            if total_count % 2 != 0 { return left_max * 2; }
            let right_min = first_right.min(second_right);
            return left_max + right_min;
        }
        if first_left > second_right {
            if first_cut == 0 { return -2_000_001; }
            high_cut = first_cut - 1;
        } else {
            low_cut = first_cut + 1;
        }
    }
    -2_000_001
}
