/// Decide binary divisibility by three with a three-state streaming DFA.
#[no_mangle]
pub unsafe extern "C" fn binary_divisibility_by_three_dfa(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length == 0 || length > 4098 { return -1; }
    let bit_count = *input;
    if !(1..=4096).contains(&bit_count) || length != bit_count as usize + 1 { return -1; }
    let bits = std::slice::from_raw_parts(input.add(1), bit_count as usize);
    let mut remainder = 0_i64;
    for &bit in bits {
        if bit != 0 && bit != 1 { return -1; }
        remainder = (2 * remainder + bit) % 3;
    }
    if output.is_null() || output_capacity < 1 { return -2; }

    *output = u8::from(remainder == 0);
    1
}
