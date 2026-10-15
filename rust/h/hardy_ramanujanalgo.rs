/// Count distinct prime divisors using factor-2 removal and odd trial divisors.
#[no_mangle]
pub extern "C" fn hardy_ramanujanalgo(value: i64) -> i64 {
    if !(1..=2_147_483_647).contains(&value) { return -1; }

    let mut remaining = value;
    let mut count = 0_i64;
    if remaining % 2 == 0 { count += 1; }
    while remaining % 2 == 0 { remaining /= 2; }

    let mut factor = 3_i64;
    while factor <= remaining / factor {
        if remaining % factor == 0 {
            count += 1;
            while remaining % factor == 0 { remaining /= factor; }
        }
        factor += 2;
    }
    if remaining > 2 { count += 1; }
    count
}
