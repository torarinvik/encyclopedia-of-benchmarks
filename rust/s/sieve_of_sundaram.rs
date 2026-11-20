/// Count primes through limit with Sundaram's index sieve.
#[no_mangle]
pub extern "C" fn sieve_of_sundaram(limit: i64) -> i64 {
    if !(0..=4096).contains(&limit) {
        return -1;
    }
    if limit < 2 {
        return 0;
    }

    let max_index = ((limit - 1) / 2) as usize;
    let mut composite = [false; 2048];
    let mut i = 1usize;
    while 2 * i * (i + 1) <= max_index {
        let mut j = i;
        loop {
            let index = i + j + 2 * i * j;
            if index > max_index {
                break;
            }
            composite[index] = true;
            j += 1;
        }
        i += 1;
    }

    let mut count = 1i64;
    for index in 1..=max_index {
        if !composite[index] {
            count += 1;
        }
    }
    count
}
