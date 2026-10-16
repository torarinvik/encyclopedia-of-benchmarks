#[no_mangle]
pub extern "C" fn simple_substitution_cipher(input: *const i64, length: usize,
                                               output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 28 || length > 284 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (mode, n64) = (values[0], values[27]);
    if (mode != 0 && mode != 1) || !(0..=256).contains(&n64) || length != 28 + n64 as usize { return -1; }
    let mut seen = [false; 26];
    for i in 0..26 {
        let value = values[1 + i];
        if !(65..=90).contains(&value) || seen[(value - 65) as usize] { return -1; }
        seen[(value - 65) as usize] = true;
    }
    let n = n64 as usize;
    if values[28..].iter().any(|&v| !(0..=127).contains(&v)) { return -1; }
    if output.is_null() || output_capacity < n { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, n) };
    for (i, slot) in out.iter_mut().enumerate() {
        let ch = values[28 + i];
        let lower = (97..=122).contains(&ch);
        let upper = (65..=90).contains(&ch);
        if !lower && !upper { *slot = ch as u8; continue; }
        let index = (ch - if lower { 97 } else { 65 }) as usize;
        let mapped = if mode == 0 { values[1 + index] - 65 } else {
            values[1..27].iter().position(|&v| v == 65 + index as i64).unwrap() as i64
        };
        *slot = ((if lower { 97 } else { 65 }) + mapped) as u8;
    }
    n as i64
}
