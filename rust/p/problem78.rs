const MAX_MODULUS: i64 = 1_000_000;
const MAX_INDEX: usize = 55_374;

fn positive_mod(value: i64, modulus: i64) -> i64 {
    let remainder = value % modulus;
    if remainder < 0 { remainder + modulus } else { remainder }
}

#[no_mangle]
pub extern "C" fn problem78(modulus: i64) -> i64 {
    if modulus < 1 || modulus > MAX_MODULUS { return -1; }
    let mut partitions = [0u32; MAX_INDEX + 1];
    partitions[0] = 1;
    for n in 1..=MAX_INDEX {
        let mut value = 0i64;
        let mut j = 1i64;
        loop {
            let first = (3 * j * j - j) / 2;
            if first > n as i64 { break; }
            let sign = if j % 2 == 0 { -1 } else { 1 };
            value = positive_mod(value + sign * i64::from(partitions[n - first as usize]), modulus);
            let second = first + j;
            if second > n as i64 { break; }
            value = positive_mod(value + sign * i64::from(partitions[n - second as usize]), modulus);
            j += 1;
        }
        if value == 0 { return n as i64; }
        partitions[n] = value as u32;
    }
    -1
}
