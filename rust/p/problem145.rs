fn count_reversible(remaining: i64, carry_in: i64, digits: &mut [i64; 9], length: i64) -> i64 {
    if remaining == 0 {
        if digits[0] == 0 || digits[(length - 1) as usize] == 0 { return 0; }
        let mut carry = carry_in;
        let mut i = length / 2 - 1;
        while i >= 0 {
            carry += digits[i as usize] + digits[(length - i - 1) as usize];
            if carry % 2 == 0 { return 0; }
            carry /= 10;
            i -= 1;
        }
        return 1;
    }
    if remaining == 1 {
        if carry_in % 2 == 0 { return 0; }
        let mut result = 0;
        for digit in 0_i64..10 {
            digits[(length / 2) as usize] = digit;
            result += count_reversible(0, (carry_in + 2 * digit) / 10, digits, length);
        }
        return result;
    }
    let mut result = 0;
    let right_index = ((length + remaining) / 2 - 1) as usize;
    let left_index = ((length - remaining) / 2) as usize;
    for digit1 in 0_i64..10 {
        digits[right_index] = digit1;
        let parity = if (carry_in + digit1) % 2 == 0 { 1 } else { 0 };
        let mut digit2 = parity;
        while digit2 < 10 {
            digits[left_index] = digit2;
            result += count_reversible(remaining - 2, (carry_in + digit1 + digit2) / 10, digits, length);
            digit2 += 2;
        }
    }
    result
}

#[no_mangle]
pub extern "C" fn problem145(max_power: i64) -> i64 {
    if max_power > 9 { return -1; }
    if max_power <= 0 { return 0; }
    let mut digits = [0_i64; 9];
    let mut total = 0;
    for length in 1..=max_power {
        if (length - 1) % 4 != 0 {
            total += count_reversible(length, 0, &mut digits, length);
        }
    }
    total
}
