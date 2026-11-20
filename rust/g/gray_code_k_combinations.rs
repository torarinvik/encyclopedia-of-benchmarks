use std::slice;

#[no_mangle]
pub unsafe extern "C" fn gray_code_k_combinations(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = slice::from_raw_parts(input, length);
    if !(0..=12).contains(&values[0]) || values[1] < 0 || values[1] > values[0] { return -1; }
    let n = values[0] as usize;
    let k = values[1] as usize;
    let smaller = k.min(n - k);
    let mut count = 1usize;
    for factor in 1..=smaller { count = count * (n - smaller + factor) / factor; }
    let required = 2 + 2 * count;
    if output.is_null() || capacity < required { return -2; }
    let bytes = slice::from_raw_parts_mut(output, required);
    bytes[0] = count as u8;
    bytes[1] = (count >> 8) as u8;

    let mut emitted = 0usize;
    for index in 0..(1usize << n) {
        let mask = index ^ (index >> 1);
        let mut remaining = mask;
        let mut population = 0usize;
        while remaining != 0 {
            remaining &= remaining - 1;
            population += 1;
        }
        if population == k {
            bytes[2 + 2 * emitted] = mask as u8;
            bytes[3 + 2 * emitted] = (mask >> 8) as u8;
            emitted += 1;
        }
    }
    count as i64
}
