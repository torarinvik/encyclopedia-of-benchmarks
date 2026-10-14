/// Stable strand sort using caller-provided temporary storage.
#[no_mangle]
pub extern "C" fn strand_sort(values: *mut i64, scratch: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let scratch = unsafe { std::slice::from_raw_parts_mut(scratch, length) };
    let mut remaining = length;
    let mut result_length = 0usize;
    while remaining > 0 {
        let mut strand_length = 0usize;
        let mut remaining_write = 0usize;
        for read in 0..remaining {
            let value = values[read];
            if strand_length == 0 || value >= scratch[strand_length - 1] {
                scratch[strand_length] = value;
                strand_length += 1;
            } else {
                values[remaining_write] = value;
                remaining_write += 1;
            }
        }
        let old_start = length - result_length;
        let new_start = old_start - strand_length;
        values.copy_within(old_start..length, new_start);
        let mut left = result_length;
        let mut right = strand_length;
        let mut destination = length;
        while left > 0 && right > 0 {
            if values[new_start + left - 1] > scratch[right - 1] {
                left -= 1;
                destination -= 1;
                values[destination] = values[new_start + left];
            } else {
                right -= 1;
                destination -= 1;
                values[destination] = scratch[right];
            }
        }
        while right > 0 {
            right -= 1;
            destination -= 1;
            values[destination] = scratch[right];
        }
        remaining = remaining_write;
        result_length += strand_length;
    }
}
