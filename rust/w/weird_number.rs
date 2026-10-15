/// Return whether a value is abundant and not semiperfect.
#[no_mangle]
pub extern "C" fn weird_number(value: i64) -> i64 {
    if !(0..=512).contains(&value) { return -1; }
    if value == 0 { return 0; }
    let mut reachable = [false; 513];
    reachable[0] = true;
    let mut divisor_sum = 0;
    for divisor in 1..=value / 2 {
        if value % divisor != 0 { continue; }
        divisor_sum += divisor;
        let mut total = value;
        while total >= divisor {
            if reachable[(total - divisor) as usize] { reachable[total as usize] = true; }
            total -= 1;
        }
    }
    i64::from(divisor_sum > value && !reachable[value as usize])
}
