/// Exponential search in an ascending sequence for the shared benchmark contract.
#[no_mangle]
pub extern "C" fn exponential_search(values: *const i64, length: usize, target: i64) -> i64 {
    let values = if length == 0 {
        &[]
    } else {
        // The C caller guarantees a valid array of `length` elements.
        unsafe { std::slice::from_raw_parts(values, length) }
    };
    if values.is_empty() {
        return -1;
    }

    let mut upper = 1usize;
    while upper < values.len() && values[upper] <= target {
        if upper > values.len() / 2 {
            upper = values.len();
        } else {
            upper *= 2;
        }
    }

    let mut low = upper / 2;
    let mut high = upper;
    while low < high {
        let middle = low + (high - low) / 2;
        let value = values[middle];
        if value == target {
            return middle as i64;
        }
        if value < target {
            low = middle + 1;
        } else {
            high = middle;
        }
    }
    -1
}
