/// Return the first Fibonacci index with the requested decimal digit count.
#[no_mangle]
pub extern "C" fn problem25(requested_digits: i64) -> i64 {
    if !(2..=1000).contains(&requested_digits) {
        return -1;
    }
    let mut previous = [0_u8; 1000];
    let mut current = [0_u8; 1000];
    let mut next = [0_u8; 1000];
    previous[0] = 1;
    current[0] = 1;
    let mut active_digits = 1_usize;
    let mut index = 2_i64;
    while active_digits < requested_digits as usize {
        let mut carry = 0_u8;
        for position in 0..active_digits {
            let sum = previous[position] + current[position] + carry;
            next[position] = sum % 10;
            carry = sum / 10;
        }
        if carry != 0 {
            next[active_digits] = carry;
            active_digits += 1;
        }
        for position in 0..active_digits {
            previous[position] = current[position];
            current[position] = next[position];
        }
        index += 1;
    }
    index
}
