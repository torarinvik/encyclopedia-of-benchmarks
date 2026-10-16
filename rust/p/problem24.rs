#[no_mangle]
pub extern "C" fn problem24(ignored: i64) -> i64 {
    if ignored != 0 {
        return -1;
    }
    let mut rank = 999_999_i64;
    let mut factorial = 362_880_i64;
    let mut used = 0_i64;
    let mut result = 0_i64;
    let mut slots = 10_i64;
    while slots > 0 {
        let mut choice = rank / factorial;
        rank %= factorial;
        let mut selected = -1_i64;
        let mut digit = 0_i64;
        while digit < 10 {
            let bit = 1_i64 << digit;
            if used & bit == 0 {
                if choice == 0 {
                    selected = digit;
                    used |= bit;
                    break;
                }
                choice -= 1;
            }
            digit += 1;
        }
        result = result * 10 + selected;
        if slots > 1 {
            factorial /= slots - 1;
        }
        slots -= 1;
    }
    result
}
