fn is_bouncy(mut value: i64) -> bool {
    let mut increasing = false;
    let mut decreasing = false;
    let mut previous = value % 10;
    value /= 10;
    while value > 0 {
        let digit = value % 10;
        if digit < previous { increasing = true; }
        if digit > previous { decreasing = true; }
        previous = digit;
        value /= 10;
    }
    increasing && decreasing
}

#[no_mangle]
pub extern "C" fn problem112(percent: i64) -> i64 {
    if !(1..=99).contains(&percent) { return -1; }
    let mut bouncy = 0_i64;
    let mut n = 1_i64;
    loop {
        if is_bouncy(n) { bouncy += 1; }
        if bouncy * 100 >= percent * n { return n; }
        n += 1;
    }
}
