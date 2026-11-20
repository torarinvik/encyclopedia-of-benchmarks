const MAX_SAMPLES: usize = 32;
const MAX_ORDER: usize = 4;
const MAX_INPUT_WORDS: usize = 45;

#[no_mangle]
pub unsafe extern "C" fn digital_filter_direct_form_ii_transposed(
    input_ptr: *const i64,
    length: usize,
    output_ptr: *mut u8,
    capacity: usize,
) -> i64 {
    if input_ptr.is_null() || !(2..=MAX_INPUT_WORDS).contains(&length) { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input_ptr, length) };
    let count_word = input[0];
    let order_word = input[1];
    if !(0..=MAX_SAMPLES as i64).contains(&count_word) || !(0..=MAX_ORDER as i64).contains(&order_word) { return -1; }
    let count = count_word as usize;
    let order = order_word as usize;
    if length != count + 2 * order + 4 { return -1; }
    let a_start = 2;
    let b_start = order + 3;
    let x_start = 2 * order + 4;
    if input[a_start] != 1 { return -1; }
    if (1..=order).any(|index| !(-1..=1).contains(&input[a_start + index])) { return -1; }
    if (0..=order).any(|index| !(-1..=1).contains(&input[b_start + index])) { return -1; }
    if input[x_start..].iter().any(|sample| !(-16..=16).contains(sample)) { return -1; }
    let bytes = count * 8;
    if bytes != 0 && (output_ptr.is_null() || capacity < bytes) { return -2; }
    if count == 0 { return 0; }

    let output = unsafe { std::slice::from_raw_parts_mut(output_ptr, bytes) };
    let mut state = [0i64; MAX_ORDER];
    for sample_index in 0..count {
        let sample = input[x_start + sample_index];
        let value = input[b_start] * sample + if order > 0 { state[0] } else { 0 };
        for stage in 0..order {
            let next_state = if stage + 1 < order { state[stage + 1] } else { 0 };
            state[stage] = next_state + input[b_start + stage + 1] * sample
                         - input[a_start + stage + 1] * value;
        }
        let bits = value as u64;
        for byte in 0..8 { output[sample_index * 8 + byte] = (bits >> (byte * 8)) as u8; }
    }
    bytes as i64
}
