const MAX_LIMIT: i64 = 10_000;
const MAX_DIGITS: usize = 64;

fn reverse_add(digits: &mut [u8; MAX_DIGITS], length: usize) -> usize {
    let mut reverse_length = length;
    while reverse_length > 0 && digits[length - reverse_length] == 0 {
        reverse_length -= 1;
    }
    let combined_length = length.max(reverse_length);
    let mut next = [0u8; MAX_DIGITS];
    let mut carry = 0i32;
    for position in 0..combined_length {
        let left = if position < length { digits[position] as i32 } else { 0 };
        let right = if position < reverse_length {
            digits[length - 1 - position] as i32
        } else {
            0
        };
        let sum = left + right + carry;
        next[position] = (sum % 10) as u8;
        carry = sum / 10;
    }
    let mut next_length = combined_length;
    if carry > 0 {
        next[next_length] = carry as u8;
        next_length += 1;
    }
    digits[..next_length].copy_from_slice(&next[..next_length]);
    next_length
}

fn is_palindrome(digits: &[u8; MAX_DIGITS], length: usize) -> bool {
    for left in 0..length / 2 {
        if digits[left] != digits[length - 1 - left] {
            return false;
        }
    }
    true
}

/// Count values below `limit` that remain non-palindromic after 50 reverse-add steps.
#[no_mangle]
pub extern "C" fn problem55(limit: i64) -> i64 {
    if !(0..=MAX_LIMIT).contains(&limit) {
        return -1;
    }
    let mut count = 0i64;
    for start in 1..limit {
        let mut digits = [0u8; MAX_DIGITS];
        let mut length = 0usize;
        let mut value = start as u64;
        while value > 0 {
            digits[length] = (value % 10) as u8;
            length += 1;
            value /= 10;
        }
        let mut became_palindrome = false;
        for _ in 0..50 {
            length = reverse_add(&mut digits, length);
            if is_palindrome(&digits, length) {
                became_palindrome = true;
                break;
            }
        }
        if !became_palindrome {
            count += 1;
        }
    }
    count
}
