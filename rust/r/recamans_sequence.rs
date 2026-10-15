#[no_mangle]
pub extern "C" fn recamans_sequence(index: i64) -> i64 {
    if !(0..=32).contains(&index) {
        return -1;
    }
    let mut seen = [false; 529];
    seen[0] = true;
    let mut previous = 0i64;
    for step in 1..=index {
        let mut candidate = previous - step;
        if candidate < 0 || seen[candidate as usize] {
            candidate = previous + step;
        }
        seen[candidate as usize] = true;
        previous = candidate;
    }
    previous
}
