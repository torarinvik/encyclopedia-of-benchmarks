#[no_mangle]
pub extern "C" fn van_ecks_sequence(position: i64) -> i64 {
    if !(1..=16).contains(&position) {
        return -1;
    }
    let mut last_seen = [0i64; 17];
    let mut previous = 0i64;
    for current in 2..=position {
        let next = if last_seen[previous as usize] == 0 {
            0
        } else {
            current - last_seen[previous as usize]
        };
        last_seen[previous as usize] = current;
        previous = next;
    }
    previous
}
