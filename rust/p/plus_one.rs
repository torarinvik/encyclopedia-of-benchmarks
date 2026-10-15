/// Increment decimal digits and write their ASCII representation.
#[no_mangle]
pub unsafe extern "C" fn plus_one(digits: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length > 256 || (length != 0 && digits.is_null()) { return -1; }
    let mut all_nines = true;
    for index in 0..length {
        let digit = *digits.add(index);
        if !(0..=9).contains(&digit) { return -1; }
        if digit != 9 { all_nines = false; }
    }
    if length > 1 && *digits == 0 { return -1; }
    let output_length = if length == 0 || all_nines { length + 1 } else { length };
    if output_capacity < output_length { return -2; }
    if length == 0 || all_nines {
        output.write(b'1');
        for index in 1..output_length { output.add(index).write(b'0'); }
        return output_length as i64;
    }
    for index in 0..length { output.add(index).write(b'0' + *digits.add(index) as u8); }
    for index in (0..length).rev() {
        if *digits.add(index) == 9 { output.add(index).write(b'0'); }
        else {
            *output.add(index) += 1;
            break;
        }
    }
    output_length as i64
}
