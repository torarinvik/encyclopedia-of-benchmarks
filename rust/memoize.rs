const MAX_INPUT_LENGTH: usize = 259;
const MAX_ARITY: usize = 4;
const MAX_CALLS: usize = 64;
const MAX_OUTPUT_BYTES: usize = 520;
const BASE: i64 = 201;

fn put_i64_le(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn memoize(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if !(0..=MAX_ARITY as i64).contains(&values[0]) || !(0..=MAX_CALLS as i64).contains(&values[1]) { return -1; }
    let arity = values[0] as usize;
    let call_count = values[1] as usize;
    if input_length != 2 + arity * call_count { return -1; }
    if values[2..].iter().any(|&value| !(-100..=100).contains(&value)) { return -1; }

    let mut keys = [[0_i64; MAX_ARITY]; MAX_CALLS];
    let mut key_results = [0_i64; MAX_CALLS];
    let mut key_count = 0_usize;
    let mut results = [0_i64; MAX_CALLS + 1];
    for call_index in 0..call_count {
        let start = 2 + call_index * arity;
        let mut key = [0_i64; MAX_ARITY];
        let mut encoded = 0_i64;
        for argument_index in 0..arity {
            let value = values[start + argument_index];
            key[argument_index] = value;
            encoded = encoded * BASE + (value + 100);
        }
        let mut found = None;
        for previous in 0..key_count {
            if keys[previous][..arity] == key[..arity] { found = Some(previous); break; }
        }
        if let Some(previous) = found {
            results[call_index] = key_results[previous];
        } else {
            keys[key_count] = key;
            key_results[key_count] = encoded;
            key_count += 1;
            results[call_index] = encoded;
        }
    }
    results[call_count] = key_count as i64;

    let output_bytes = 8 * (call_count + 1);
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    for index in 0..=call_count { put_i64_le(&mut staged, index * 8, results[index]); }
    if output.is_null() || output_capacity < output_bytes { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    output_bytes as i64
}
