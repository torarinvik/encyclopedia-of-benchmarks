const MAX_TRACE_VALUES: usize = 256;
const MAX_KEY: i64 = 1_000_000_000;

#[no_mangle]
pub unsafe extern "C" fn bloom_filter(
    trace: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if length > MAX_TRACE_VALUES || length % 2 != 0 || (length != 0 && trace.is_null()) {
        return -1;
    }
    let trace = if length == 0 { &[] } else { std::slice::from_raw_parts(trace, length) };
    let mut query_count = 0usize;
    for pair in trace.chunks_exact(2) {
        let operation = pair[0];
        let key = pair[1];
        if (operation != 1 && operation != 2) || !(0..=MAX_KEY).contains(&key) {
            return -1;
        }
        if operation == 2 { query_count += 1; }
    }
    if output_capacity < query_count || (query_count != 0 && output.is_null()) {
        return -2;
    }

    let mut bits = 0u64;
    let mut written = 0usize;
    for pair in trace.chunks_exact(2) {
        let key = pair[1];
        let first = ((key * 17 + 3) % 64) as u32;
        let second = ((key * 31 + 7) % 64) as u32;
        let first_mask = 1u64 << first;
        let second_mask = 1u64 << second;
        if pair[0] == 1 {
            bits |= first_mask | second_mask;
        } else {
            *output.add(written) = ((bits & first_mask) != 0 && (bits & second_mask) != 0) as u8;
            written += 1;
        }
    }
    written as i64
}
