/// Direct permutation port of TheAlgorithms/Python Project Euler 43.
fn next_permutation(digits: &mut [i64; 10]) -> bool {
    let mut i: isize = 8;
    while i >= 0 && digits[i as usize] >= digits[i as usize + 1] { i -= 1; }
    if i < 0 { return false; }
    let i = i as usize;
    let mut j = 9;
    while digits[j] <= digits[i] { j -= 1; }
    digits.swap(i, j);
    digits[i + 1..].reverse();
    true
}

#[no_mangle]
pub extern "C" fn problem43(n: i64) -> i64 {
    if n != 10 { return -1; }
    let mut digits = [0,1,2,3,4,5,6,7,8,9];
    let divisors = [7,11,13,17];
    let mut total = 0i64;
    loop {
        if digits[3]%2 == 0 && (digits[2]+digits[3]+digits[4])%3 == 0 && digits[5]%5 == 0 {
            let valid = (0..4).all(|i| (digits[i+4]*100+digits[i+5]*10+digits[i+6])%divisors[i] == 0);
            if valid { let value = digits.iter().fold(0i64, |acc, &digit| acc*10+digit); total += value; }
        }
        if !next_permutation(&mut digits) { break; }
    }
    total
}
