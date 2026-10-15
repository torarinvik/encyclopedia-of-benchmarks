/// Match the product's decimal digits against the combined factor digits.
fn decimal_length(mut value: u64) -> u32 {
    let mut length = 0;
    loop {
        length += 1;
        value /= 10;
        if value == 0 { break; }
    }
    length
}

#[no_mangle]
pub extern "C" fn vampire_number(left_input: u64, right_input: u64) -> i64 {
    if !(1..=9999).contains(&left_input) || !(1..=9999).contains(&right_input) { return -1; }
    if decimal_length(left_input) != decimal_length(right_input) { return 0; }
    let mut counts = [0i32; 10];
    let mut product = left_input * right_input;
    let mut left = left_input;
    let mut right = right_input;
    while product != 0 { counts[(product % 10) as usize] += 1; product /= 10; }
    while left != 0 { counts[(left % 10) as usize] -= 1; left /= 10; }
    while right != 0 { counts[(right % 10) as usize] -= 1; right /= 10; }
    if counts.iter().any(|&count| count != 0) { 0 } else { 1 }
}
