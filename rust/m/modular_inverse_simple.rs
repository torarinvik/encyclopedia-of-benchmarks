/// Simple iterative modular inverse for bounded coprime positive inputs.
fn gcd_u64(mut left: u64, mut right: u64) -> u64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

#[no_mangle]
pub extern "C" fn modular_inverse_simple(x_input: i64, y_input: i64) -> i64 {
    if !(1..=999).contains(&x_input) || !(2..=1000).contains(&y_input) { return -1; }
    let x = x_input as u64;
    let y = y_input as u64;
    if gcd_u64(x, y) != 1 { return -1; }

    let mut auxiliary = 0_u64;
    let mut iteration = 0_u64;
    loop {
        auxiliary = y * iteration + 1;
        iteration += 1;
        if auxiliary % x == 0 { break; }
    }
    (auxiliary / x) as i64
}
