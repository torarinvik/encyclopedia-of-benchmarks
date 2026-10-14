/// Interpolation search in an ascending sequence for the shared benchmark contract.
#[no_mangle]
pub extern "C" fn interpolation_search(values: *const i64, length: usize, target: i64) -> i64 {
    if length == 0 {
        return -1;
    }
    // The C caller guarantees a valid array of `length` elements.
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut low = 0usize;
    let mut high = length - 1;

    while low <= high {
        let low_value = values[low];
        let high_value = values[high];
        if target < low_value || target > high_value {
            return -1;
        }
        if low_value == high_value {
            return if low_value == target { low as i64 } else { -1 };
        }
        let numerator = (target - low_value) * (high - low) as i64;
        let denominator = high_value - low_value;
        let position = low + (numerator / denominator) as usize;
        let value = values[position];
        if value == target {
            return position as i64;
        }
        if value < target {
            low = position + 1;
        } else {
            if position == 0 {
                return -1;
            }
            high = position - 1;
        }
    }
    -1
}
