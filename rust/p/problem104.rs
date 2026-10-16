const MAX_FIBONACCI_INDEX: usize = 1_000_002;
const MAX_LIMBS: usize = 24_000;
const LIMB_BASE: u64 = 1_000_000_000;

fn is_pandigital_1_to_9(mut value: u32) -> bool {
    let mut mask = 0u16;
    for _ in 0..9 {
        let digit = value % 10;
        let bit = 1u16 << digit;
        if digit == 0 || mask & bit != 0 { return false; }
        mask |= bit;
        value /= 10;
    }
    value == 0 && mask == 0x3fe
}
fn power_of_ten(exponent: u32) -> u32 {
    let mut value = 1u32;
    for _ in 0..exponent { value *= 10; }
    value
}
fn leading_nine_digits(limbs: &[u32], length: usize) -> u32 {
    let top = limbs[length - 1];
    let mut width = 0u32;
    let mut value = top;
    while value > 0 { width += 1; value /= 10; }
    if width >= 9 || length == 1 { return top; }
    let fill = 9 - width;
    let next_prefix = limbs[length - 2] / power_of_ten(width);
    top * power_of_ten(fill) + next_prefix
}

#[no_mangle]
pub extern "C" fn problem104(placeholder: i64) -> i64 {
    if placeholder != 0 { return -1; }
    let mut first_buffer = [0u32; MAX_LIMBS];
    let mut second_buffer = [0u32; MAX_LIMBS];
    first_buffer[0] = 1;
    second_buffer[0] = 1;
    let mut previous: &mut [u32] = &mut first_buffer;
    let mut current: &mut [u32] = &mut second_buffer;
    let (mut previous_length, mut current_length) = (1usize, 1usize);

    for index in 3..=MAX_FIBONACCI_INDEX {
        let sum_length = previous_length.max(current_length);
        let mut carry = 0u64;
        for limb in 0..sum_length {
            let left = if limb < previous_length { previous[limb] as u64 } else { 0 };
            let right = if limb < current_length { current[limb] as u64 } else { 0 };
            let sum = left + right + carry;
            previous[limb] = (sum % LIMB_BASE) as u32;
            carry = sum / LIMB_BASE;
        }
        let mut next_length = sum_length;
        if carry != 0 {
            if next_length == MAX_LIMBS { return -1; }
            previous[next_length] = carry as u32;
            next_length += 1;
        }
        std::mem::swap(&mut previous, &mut current);
        previous_length = current_length;
        current_length = next_length;
        if is_pandigital_1_to_9(current[0])
            && is_pandigital_1_to_9(leading_nine_digits(current, current_length)) { return index as i64; }
    }
    -1
}
