const MAX_INPUT_LENGTH: usize = 260;
const MAX_TEXT_LENGTH: usize = 256;
const MAX_KEY: usize = 256;

#[no_mangle]
pub unsafe extern "C" fn skytale_cipher(input: *const i64, length: usize,
                                         output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    if !(0..=1).contains(&values[0]) || !(1..=MAX_KEY as i64).contains(&values[1]) ||
        !(0..=MAX_TEXT_LENGTH as i64).contains(&values[2]) { return -1; }
    let mode = values[0] as usize;
    let key = values[1] as usize;
    let n = values[2] as usize;
    if length != 3 + n || values[3..].iter().any(|&value| !(0..=127).contains(&value)) { return -1; }
    if output.is_null() || capacity < n { return -2; }
    let output = core::slice::from_raw_parts_mut(output, n);

    if mode == 0 {
        let mut out = 0;
        for row in 0..key {
            let mut position = row;
            while position < n { output[out] = values[3 + position] as u8; out += 1; position += key; }
        }
    } else {
        let mut starts = [0usize; MAX_KEY];
        let mut used = [0usize; MAX_KEY];
        let (base, extra) = (n / key, n % key);
        for row in 1..key {
            let increment = if row - 1 < extra { 1 } else { 0 };
            starts[row] = starts[row - 1] + base + increment;
        }
        for position in 0..n {
            let row = position % key;
            output[position] = values[3 + starts[row] + used[row]] as u8;
            used[row] += 1;
        }
    }
    n as i64
}
