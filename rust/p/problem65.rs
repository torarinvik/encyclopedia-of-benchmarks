const MAX_DIGITS: usize = 256;

#[no_mangle]
pub extern "C" fn problem65(max_n: i64) -> i64 {
    if !(1..=100).contains(&max_n) { return -1; }
    let mut previous = [0i64; MAX_DIGITS];
    let mut current = [0i64; MAX_DIGITS];
    let mut next = [0i64; MAX_DIGITS];
    previous[0] = 1;
    current[0] = 2;
    let mut previous_length = 1usize;
    let mut current_length = 1usize;
    for i in 2..=max_n {
        let coefficient = if i % 3 == 0 { (2 * i) / 3 } else { 1 };
        let mut carry = 0i64;
        for position in 0..current_length {
            let old = if position < previous_length { previous[position] } else { 0 };
            let total = coefficient * current[position] + old + carry;
            next[position] = total % 10;
            carry = total / 10;
        }
        let mut next_length = current_length;
        while carry != 0 {
            next[next_length] = carry % 10;
            next_length += 1;
            carry /= 10;
        }
        previous[..current_length].copy_from_slice(&current[..current_length]);
        current[..next_length].copy_from_slice(&next[..next_length]);
        previous_length = current_length;
        current_length = next_length;
    }
    current[..current_length].iter().sum()
}
