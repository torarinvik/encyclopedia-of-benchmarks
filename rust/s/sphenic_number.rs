fn source_sieve_flag(value: i64) -> bool {
    if value < 2 { return true; }
    let mut divisor = 2;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor += 1;
    }
    true
}

#[no_mangle]
pub extern "C" fn sphenic_number(value: i64) -> i64 {
    if !(0..=1000).contains(&value) { return -1; }
    let mut first = [0_i64; 3];
    let mut count = 0_i64;
    let mut divisor = 1_i64;
    while divisor <= value {
        if value % divisor == 0 && count < 9 {
            if count < 3 { first[count as usize] = divisor; }
            count += 1;
        }
        divisor += 1;
    }
    i64::from(count == 8 && source_sieve_flag(first[0])
        && source_sieve_flag(first[1]) && source_sieve_flag(first[2]))
}
