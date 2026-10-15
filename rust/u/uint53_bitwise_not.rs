/// Complement every bit in the fixed-width unsigned 53-bit domain.
const MAX_UINT53: i64 = 9_007_199_254_740_991;
const TWO_TO_53: i64 = 9_007_199_254_740_992;

#[no_mangle]
pub extern "C" fn uint53_bitwise_not(n: i64) -> i64 {
    if !(0..=MAX_UINT53).contains(&n) {
        return -1;
    }

    let mut current = n;
    let mut result: i64 = 0;
    let mut bit: i64 = 1;
    while current >= 255 {
        let byte = current % 256;
        result += (255 - byte) * bit;
        current = (current - byte) / 256;
        bit *= 256;
    }
    while current != 0 {
        let n_bit = current % 2;
        result += (1 - n_bit) * bit;
        current = (current - n_bit) / 2;
        bit *= 2;
    }

    TWO_TO_53 - bit + result
}
