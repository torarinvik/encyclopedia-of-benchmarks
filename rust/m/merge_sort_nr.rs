const MAX_VALUES: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn merge_sort_nr(values: *mut i64, length: usize) {
    if length > MAX_VALUES {
        return;
    }
    let mut scratch = [0_i64; MAX_VALUES];
    let mut width = 1;
    while width < length {
        let mut start = 0;
        while start < length {
            let middle = (start + width).min(length);
            let end = (middle + width).min(length);
            let mut left = start;
            let mut right = middle;
            let mut output = start;
            while left < middle && right < end {
                if *values.add(left) <= *values.add(right) {
                    scratch[output] = *values.add(left);
                    left += 1;
                } else {
                    scratch[output] = *values.add(right);
                    right += 1;
                }
                output += 1;
            }
            while left < middle {
                scratch[output] = *values.add(left);
                left += 1;
                output += 1;
            }
            while right < end {
                scratch[output] = *values.add(right);
                right += 1;
                output += 1;
            }
            start += width * 2;
        }
        for index in 0..length {
            *values.add(index) = scratch[index];
        }
        width *= 2;
    }
}
