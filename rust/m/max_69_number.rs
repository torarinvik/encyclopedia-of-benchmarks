#[no_mangle]
pub extern "C" fn max_69_number(value: i64) -> i64 {
    if !(1..=999_999_999_999_999_999).contains(&value) {
        return -1;
    }
    let mut place = 1_i64;
    while place <= value / 10 {
        place *= 10;
    }
    while place > 0 {
        let digit = (value / place) % 10;
        if digit == 6 {
            return value + 3 * place;
        }
        if digit != 9 {
            return -1;
        }
        place /= 10;
    }
    -1
}
