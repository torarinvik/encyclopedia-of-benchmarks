/// Brute-force next-greater-value search for each node in list order.
#[no_mangle]
pub unsafe extern "C" fn next_greater_nodes(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if length == 0 || length > 4096 || values.is_null() { return -1; }
    for index in 0..length {
        let value = *values.add(index);
        if !(1..=1_000_000_000).contains(&value) { return -1; }
    }
    let required = 4 * length;
    if output_capacity < required || output.is_null() { return -2; }
    for index in 0..length {
        let value = *values.add(index);
        let mut next_greater = 0_i64;
        for later in index + 1..length {
            let candidate = *values.add(later);
            if candidate > value {
                next_greater = candidate;
                break;
            }
        }
        let encoded = next_greater as u32;
        *output.add(4 * index) = encoded as u8;
        *output.add(4 * index + 1) = (encoded >> 8) as u8;
        *output.add(4 * index + 2) = (encoded >> 16) as u8;
        *output.add(4 * index + 3) = (encoded >> 24) as u8;
    }
    length as i64
}
