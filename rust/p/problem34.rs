const DIGIT_FACTORIALS: [i64; 10] = [1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880];

#[no_mangle]
pub extern "C" fn problem34(ignored: i64) -> i64 {
    if ignored != 0 {
        return -1;
    }
    let mut total = 0i64;
    for number in 3i64..=2_540_160 {
        let mut remaining = number;
        let mut digit_sum = 0i64;
        while remaining > 0 {
            digit_sum += DIGIT_FACTORIALS[(remaining % 10) as usize];
            remaining /= 10;
        }
        if digit_sum == number {
            total += number;
        }
    }
    total
}
