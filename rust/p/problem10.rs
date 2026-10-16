#[no_mangle]
pub extern "C" fn problem10(limit: i64) -> i64 {
    if !(0..=2_000_000).contains(&limit) {
        return -1;
    }
    let mut composite = [false; 1_000_000];
    let odd_count = (limit / 2) as usize;
    let mut sum = if limit > 2 { 2 } else { 0 };
    let mut prime = 3i64;
    while prime * prime < limit {
        if !composite[(prime / 2) as usize] {
            let mut index = (prime * prime / 2) as usize;
            while index < odd_count {
                composite[index] = true;
                index += prime as usize;
            }
        }
        prime += 2;
    }
    for index in 1..odd_count {
        if !composite[index] {
            sum += (2 * index + 1) as i64;
        }
    }
    sum
}
