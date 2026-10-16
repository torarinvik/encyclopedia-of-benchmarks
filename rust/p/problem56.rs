fn multiply_digits(digits: &mut [u8; 512], length: usize, factor: usize) -> usize {
    let mut carry = 0usize;
    for digit in digits.iter_mut().take(length) {
        let value = usize::from(*digit) * factor + carry;
        *digit = (value % 10) as u8;
        carry = value / 10;
    }
    let mut count = length;
    while carry > 0 { digits[count] = (carry % 10) as u8; count += 1; carry /= 10; }
    count
}
#[no_mangle]
pub extern "C" fn problem56(a: i64, b: i64) -> i64 {
    if !(1..=200).contains(&a) || !(1..=200).contains(&b) { return -1; }
    let mut best = 0i64;
    for base in 0..a as usize {
        let mut digits = [0u8; 512]; digits[0] = 1;
        let mut length = 1usize;
        for power in 0..b {
            let sum: i64 = digits[..length].iter().map(|&digit| i64::from(digit)).sum();
            best = best.max(sum);
            if power + 1 < b { length = multiply_digits(&mut digits, length, base); }
        }
    }
    best
}
