/// Ternary search in an ascending sequence for the shared benchmark contract.
#[no_mangle]
pub extern "C" fn ternary_search(values: *const i64, length: usize, target: i64) -> i64 {
    // The C caller guarantees a valid array even when length is zero.
    let values = if length == 0 {
        &[]
    } else {
        unsafe { std::slice::from_raw_parts(values, length) }
    };
    let mut low = 0usize;
    let mut high = values.len();
    while low < high {
        let third = (high - low) / 3;
        let first = low + third;
        let second = high - third - 1;
        let first_value = values[first];
        let second_value = values[second];
        if first_value == target {
            return first as i64;
        }
        if second_value == target {
            return second as i64;
        }
        if target < first_value {
            high = first;
        } else if target > second_value {
            low = second + 1;
        } else {
            low = first + 1;
            high = second;
        }
    }
    -1
}
