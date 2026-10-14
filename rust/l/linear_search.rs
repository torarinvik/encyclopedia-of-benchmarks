/// First-match linear search for the shared benchmark contract.
/// The pointer and length parameters expose the routine through the C ABI.
#[no_mangle]
pub extern "C" fn linear_search(values: *const i64, length: usize, target: i64) -> i64 {
    let values = if length == 0 {
        &[]
    } else {
        // The C caller guarantees a valid array of `length` elements.
        unsafe { std::slice::from_raw_parts(values, length) }
    };

    for (index, value) in values.iter().enumerate() {
        if *value == target {
            // The workload limits input lengths to i64::MAX.
            return index as i64;
        }
    }

    -1
}
