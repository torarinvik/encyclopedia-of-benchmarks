/// Count powers whose decimal digit count equals the exponent.
#[no_mangle]
pub extern "C" fn problem63(max_base: i64, max_power: i64) -> i64 {
    let base_limit = max_base.min(10);
    let power_limit = max_power.min(22);
    let mut count = 0_i64;
    let mut base = 1_i64;
    while base < base_limit {
        let mut power = 1_i64;
        while power < power_limit {
            let mut digits = [0_i32; 32];
            digits[0] = 1;
            let mut length = 1_usize;
            for _ in 0..power {
                let mut carry = 0_i32;
                for digit in &mut digits[..length] {
                    let value = *digit * base as i32 + carry;
                    *digit = value % 10;
                    carry = value / 10;
                }
                while carry > 0 {
                    digits[length] = carry % 10;
                    length += 1;
                    carry /= 10;
                }
            }
            if length as i64 == power { count += 1; }
            power += 1;
        }
        base += 1;
    }
    count
}
