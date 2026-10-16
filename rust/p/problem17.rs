/// Count letters in the British English names for 1 through `limit`.
#[no_mangle]
pub extern "C" fn problem17(limit: i64) -> i64 {
    if !(0..=1000).contains(&limit) {
        return -1;
    }
    const ONES: [i64; 20] = [0, 3, 3, 5, 4, 4, 3, 5, 5, 4, 3, 6, 6, 8, 8, 7, 7, 9, 8, 8];
    const TENS: [i64; 10] = [0, 0, 6, 6, 5, 5, 5, 7, 6, 6];
    let mut total = 0;
    for value in 1..=limit {
        if value == 1000 {
            total += ONES[1] + 8;
            continue;
        }
        let mut remainder = value;
        if value >= 100 {
            total += ONES[(value / 100) as usize] + 7;
            remainder = value % 100;
            if remainder != 0 {
                total += 3;
            }
        }
        if remainder < 20 {
            total += ONES[remainder as usize];
        } else {
            total += TENS[(remainder / 10) as usize] + ONES[(remainder % 10) as usize];
        }
    }
    total
}
