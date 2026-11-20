/// Lucas digit product for a binomial coefficient modulo three.
fn triangle_binomial_mod_three(mut n: i64, mut k: i64) -> i64 {
    let mut coefficient = 1i64;
    while n > 0 || k > 0 {
        let n_digit = n % 3;
        let k_digit = k % 3;
        if k_digit > n_digit { return 0; }
        if n_digit == 2 && k_digit == 1 { coefficient = (2 * coefficient) % 3; }
        n /= 3;
        k /= 3;
    }
    coefficient
}

#[no_mangle]
pub extern "C" fn coloured_triangle_reduction(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=258).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n = values[0];
    if !(1..=256).contains(&n) || length != n as usize + 1 { return -1; }
    let colors = &values[1..];
    if colors.iter().any(|&color| !(0..=2).contains(&color)) { return -1; }

    let rounds = n - 1;
    let mut total = 0i64;
    for (index, &color) in colors.iter().enumerate() {
        total = (total + triangle_binomial_mod_three(rounds, index as i64) * color) % 3;
    }
    if rounds % 2 == 0 { total } else { (3 - total) % 3 }
}
