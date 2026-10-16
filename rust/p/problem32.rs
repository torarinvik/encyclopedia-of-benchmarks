fn next_permutation(digits: &mut [i64; 9]) -> bool {
    let mut pivot = 7_isize;
    while pivot >= 0 && digits[pivot as usize] >= digits[pivot as usize + 1] {
        pivot -= 1;
    }
    if pivot < 0 {
        return false;
    }
    let pivot = pivot as usize;
    let mut successor = 8;
    while digits[successor] <= digits[pivot] {
        successor -= 1;
    }
    digits.swap(pivot, successor);
    digits[pivot + 1..].reverse();
    true
}

/// Sum distinct products in 1-to-9 pandigital multiplication identities.
#[no_mangle]
pub extern "C" fn problem32(ignored: i64) -> i64 {
    if ignored != 0 {
        return -1;
    }
    let mut digits = [1_i64, 2, 3, 4, 5, 6, 7, 8, 9];
    let mut seen = [false; 10000];
    loop {
        let product = digits[5] * 1000 + digits[6] * 100 + digits[7] * 10 + digits[8];
        let two_digit = digits[0] * 10 + digits[1];
        let three_digit = digits[2] * 100 + digits[3] * 10 + digits[4];
        let four_digit = digits[1] * 1000 + digits[2] * 100 + digits[3] * 10 + digits[4];
        if two_digit * three_digit == product || digits[0] * four_digit == product {
            seen[product as usize] = true;
        }
        if !next_permutation(&mut digits) {
            break;
        }
    }
    seen.iter().enumerate().filter_map(|(value, &present)| present.then_some(value as i64)).sum()
}
