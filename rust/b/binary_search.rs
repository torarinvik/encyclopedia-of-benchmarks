/// Binary search in an ascending sequence for the shared benchmark contract.
#[no_mangle]
pub extern "C" fn binary_search(values: *const i64, length: usize, target: i64) -> i64 {
    let values = if length == 0 {
        &[]
    } else {
        // The C caller guarantees a valid array of `length` elements.
        unsafe { std::slice::from_raw_parts(values, length) }
    };

    let mut low = 0usize;
    let mut high = values.len();
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
