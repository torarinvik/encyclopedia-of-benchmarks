const LOGINS: [i64; 50] = [
    319, 680, 180, 690, 129, 620, 762, 689, 762, 318,
    368, 710, 720, 710, 629, 168, 160, 689, 716, 731,
    736, 729, 316, 729, 729, 710, 769, 290, 719, 680,
    318, 389, 162, 289, 162, 718, 729, 319, 790, 680,
    890, 362, 319, 760, 316, 729, 380, 319, 728, 716,
];

fn next_permutation(digits: &mut [i64], length: usize) -> bool {
    let mut pivot = length as isize - 2;
    while pivot >= 0 && digits[pivot as usize] >= digits[pivot as usize + 1] { pivot -= 1; }
    if pivot < 0 { return false; }
    let pivot = pivot as usize;
    let mut successor = length - 1;
    while digits[successor] <= digits[pivot] { successor -= 1; }
    digits.swap(pivot, successor);
    digits[pivot + 1..length].reverse();
    true
}

#[no_mangle]
pub extern "C" fn problem79(placeholder: i64) -> i64 {
    if placeholder != 0 { return -1; }
    let mut present = [false; 10];
    for login in LOGINS {
        present[(login / 100) as usize] = true;
        present[((login / 10) % 10) as usize] = true;
        present[(login % 10) as usize] = true;
    }
    let mut digits = [0_i64; 10];
    let mut length = 0;
    for digit in 0..10 {
        if present[digit] { digits[length] = digit as i64; length += 1; }
    }
    loop {
        let mut positions = [-1_i64; 10];
        for i in 0..length { positions[digits[i] as usize] = i as i64; }
        let mut satisfied = true;
        for login in LOGINS {
            let first = (login / 100) as usize;
            let second = ((login / 10) % 10) as usize;
            let third = (login % 10) as usize;
            if !(positions[first] < positions[second] && positions[second] < positions[third]) { satisfied = false; break; }
        }
        if satisfied {
            let mut passcode = 0_i64;
            for digit in &digits[..length] { passcode = passcode * 10 + *digit; }
            return passcode;
        }
        if !next_permutation(&mut digits, length) { break; }
    }
    -1
}
