fn digit_sum(mut value: i64) -> i64 {
    let mut sum = 0;
    while value > 0 { sum += value % 10; value /= 10; }
    sum
}

#[no_mangle]
pub extern "C" fn problem119(index: i64) -> i64 {
    if !(1..=30).contains(&index) { return -1; }
    let mut values = [0_i64; 10000];
    let mut count = 0_usize;
    for base in 2_i64..100 {
        let mut value = base * base;
        for _exponent in 2..100 {
            if digit_sum(value) == base { values[count] = value; count += 1; }
            if value > i64::MAX / base { break; }
            value *= base;
        }
    }
    for i in 1..count {
        let value = values[i];
        let mut j = i;
        while j > 0 && values[j - 1] > value { values[j] = values[j - 1]; j -= 1; }
        values[j] = value;
    }
    values[(index - 1) as usize]
}
